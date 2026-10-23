#!/usr/bin/env python3
"""Package a tested macOS archive with ASC-provisioned signing assets.

Uses a dedicated temporary keychain. Does not unlock or edit the login keychain.
Passwords are read from protected files and are never logged.
"""
import argparse
import hashlib
import json
import plistlib
import re
import secrets
import shutil
import subprocess
import tempfile
from pathlib import Path


def run(label, args, **kwargs):
    result = subprocess.run(args, capture_output=True, **kwargs)
    if result.returncode:
        # Never include argv: security commands receive keychain passwords.
        message = result.stderr.decode(errors="replace") if isinstance(result.stderr, bytes) else result.stderr
        raise RuntimeError(f"{label} failed: {message.strip()}")
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument("--app-identity", type=Path, required=True)
    parser.add_argument("--app-identity-password-file", type=Path, required=True)
    parser.add_argument("--installer-certificate", type=Path, required=True)
    parser.add_argument("--installer-private-key", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise RuntimeError(f"Output already exists: {args.output}")
    apps = list((args.archive / "Products/Applications").glob("*.app"))
    if len(apps) != 1:
        raise RuntimeError("Expected exactly one application in archive")
    source_app = apps[0]
    profile = plistlib.loads(run("Decode profile", ["security", "cms", "-D", "-i", str(args.profile)]))
    info = plistlib.loads((source_app / "Contents/Info.plist").read_bytes())
    team = profile["TeamIdentifier"][0]
    app_id = f"{team}.{info['CFBundleIdentifier']}"
    if profile["Entitlements"]["com.apple.application-identifier"] != app_id:
        raise RuntimeError("Provisioning profile does not match archive bundle ID")
    app_identity = hashlib.sha1(profile["DeveloperCertificates"][0]).hexdigest().upper()
    entitlements = plistlib.loads(run("Read entitlements", ["codesign", "-d", "--entitlements", ":-", str(source_app)]))
    entitlements.update(profile["Entitlements"])
    for key in ("get-task-allow", "com.apple.security.get-task-allow"):
        entitlements.pop(key, None)
    if "keychain-access-groups" in entitlements:
        entitlements["keychain-access-groups"] = [group.replace("*", info["CFBundleIdentifier"])
                                                for group in entitlements["keychain-access-groups"]]
    if not entitlements.get("com.apple.security.app-sandbox"):
        raise RuntimeError("App Sandbox must remain enabled")

    with tempfile.TemporaryDirectory(prefix="PDFLibrarian-asc-signing-") as staging:
        staging = Path(staging)
        keychain = staging / "signing.keychain-db"
        password = secrets.token_urlsafe(32)
        password_file = staging / "password"
        password_file.write_text(password)
        password_file.chmod(0o600)
        installer_pem = staging / "installer.pem"
        run("Convert installer certificate", ["openssl", "x509", "-inform", "DER", "-in", str(args.installer_certificate), "-out", str(installer_pem)])
        subject = run("Read installer identity", ["openssl", "x509", "-in", str(installer_pem), "-noout", "-subject", "-nameopt", "RFC2253"], text=True)
        match = re.search(r"(?:subject=\s*|,)CN=([^,]+)", subject)
        if not match:
            raise RuntimeError("Could not determine installer certificate common name")
        installer_identity = match.group(1)
        installer_p12 = staging / "installer.p12"
        run("Build protected installer identity", ["openssl", "pkcs12", "-export", "-inkey", str(args.installer_private_key),
             "-in", str(installer_pem), "-out", str(installer_p12), "-passout", f"file:{password_file}"])
        run("Create temporary keychain", ["security", "create-keychain", "-p", password, str(keychain)])
        try:
            run("Configure temporary keychain", ["security", "set-keychain-settings", "-lut", "3600", str(keychain)])
            run("Unlock temporary keychain", ["security", "unlock-keychain", "-p", password, str(keychain)])
            app_password = args.app_identity_password_file.read_text().strip()
            run("Import application identity", ["security", "import", str(args.app_identity), "-k", str(keychain), "-P", app_password, "-T", "/usr/bin/codesign"])
            run("Import installer identity", ["security", "import", str(installer_p12), "-k", str(keychain), "-P", password,
                 "-T", "/usr/bin/productbuild", "-T", "/usr/bin/productsign"])
            run("Authorize signing tools in temporary keychain", ["security", "set-key-partition-list", "-S", "apple-tool:,apple:,codesign:", "-s", "-k", password, str(keychain)])
            app = staging / source_app.name
            run("Copy tested archive", ["ditto", "--noextattr", "--norsrc", str(source_app), str(app)])
            shutil.copyfile(args.profile, app / "Contents/embedded.provisionprofile")
            entitlements_path = staging / "entitlements.plist"
            entitlements_path.write_bytes(plistlib.dumps(entitlements))
            run("Sign application", ["codesign", "--force", "--sign", app_identity, "--keychain", str(keychain),
                 "--entitlements", str(entitlements_path), "--preserve-metadata=identifier,flags,runtime", "--generate-entitlement-der", str(app)])
            run("Verify application", ["codesign", "--verify", "--deep", "--strict", str(app)])
            package = staging / "PDF Librarian.pkg"
            run("Sign installer package", ["productbuild", "--component", str(app), "/Applications", "--sign", installer_identity,
                 "--keychain", str(keychain), str(package)])
            args.output.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(package, args.output)
            print(json.dumps({"package": str(args.output), "bundle_id": info["CFBundleIdentifier"],
                  "version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"],
                  "profile_uuid": profile["UUID"], "app_certificate_sha1": app_identity,
                  "installer_identity": installer_identity, "login_keychain_modified": False}, ensure_ascii=False))
        finally:
            run("Remove temporary signing keychain", ["security", "delete-keychain", str(keychain)])


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        raise SystemExit(str(error))
