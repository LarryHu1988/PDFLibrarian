"""Sign a direct-distribution copy in a temporary keychain; leave login keychain untouched."""
import argparse, json, os, plistlib, secrets, shutil, subprocess, tempfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--archive',required=True);p.add_argument('--signing-dir',required=True);p.add_argument('--output-dir',required=True);a=p.parse_args()
def run(args):
 r=subprocess.run([str(x) for x in args],capture_output=True)
 if r.returncode:raise RuntimeError(r.stderr.decode(errors='replace'))
 return r.stdout
source=next((Path(a.archive)/'Products/Applications').glob('*.app'));out=Path(a.output_dir);out.mkdir(parents=True,exist_ok=True);app=out/source.name
if app.exists():raise RuntimeError('Refusing to replace existing distribution app')
shutil.copytree(source,app,symlinks=True)
# iCloud/Finder may add these attributes to this generated output.
for attr in ['com.apple.FinderInfo','com.apple.ResourceFork']:
 subprocess.run(['xattr','-r','-d',attr,str(app)],capture_output=True)
signing=Path(a.signing_dir)
with tempfile.TemporaryDirectory(prefix='PDFLibrarian-devid-') as temp:
 t=Path(temp);pw=secrets.token_urlsafe(32);(t/'password').write_text(pw);os.chmod(t/'password',0o600)
 run(['openssl','x509','-inform','DER','-in',signing/'developer-id.cer','-out',t/'certificate.pem'])
 run(['openssl','pkcs12','-export','-out',t/'identity.p12','-inkey',signing/'developer-id.key','-in',t/'certificate.pem','-passout',f'file:{t}/password'])
 kc=t/'signing.keychain-db'
 try:
  run(['security','create-keychain','-p',pw,kc]);run(['security','unlock-keychain','-p',pw,kc])
  run(['security','import',t/'identity.p12','-k',kc,'-P',pw,'-T','/usr/bin/codesign'])
  run(['security','import',signing/'DeveloperIDG2CA.cer','-k',kc,'-T','/usr/bin/codesign'])
  run(['security','set-key-partition-list','-S','apple-tool:,apple:,codesign:','-s','-k',pw,kc])
  sha=run(['openssl','x509','-inform','DER','-in',signing/'developer-id.cer','-noout','-fingerprint','-sha1']).decode().strip().split('=')[1].replace(':','')
  ent=Path(__file__).resolve().parents[1]/'Sources/PDFLibrarian/PDFLibrarian.entitlements'
  run(['codesign','--force','--sign',sha,'--keychain',kc,'--options','runtime','--timestamp','--entitlements',ent,app])
  run(['codesign','--verify','--deep','--strict',app])
  info=plistlib.loads((app/'Contents/Info.plist').read_bytes());zipfile=out/f"PDFLibrarian-{info['CFBundleShortVersionString']}.zip"
  run(['ditto','-c','-k','--keepParent',app,zipfile])
  print(json.dumps({'app':str(app),'zip':str(zipfile),'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],'certificate_sha1':sha,'login_keychain_modified':False}))
 finally:
  run(['security','delete-keychain',kc])
