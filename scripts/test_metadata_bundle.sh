#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP="${1:?Usage: test_metadata_bundle.sh BUILT_APP_PATH}"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/PDFLibrarian-bundle-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
APP="$TEST_DIR/MetadataBundleSmoke.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# Test the built artifact's resources, not a freshly repackaged dependency.
cp -R "$SOURCE_APP/Contents/Resources/ExifTool" "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.larry.pdflibrarian.metadata-bundle-test</string>
<key>CFBundleExecutable</key><string>MetadataBundleSmoke</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun swiftc -O -o "$APP/Contents/MacOS/MetadataBundleSmoke" \
  "$ROOT_DIR/tests/MetadataBundleSmoke.swift" \
  "$ROOT_DIR/Sources/PDFLibrarian/MetadataService.swift" \
  "$ROOT_DIR/Sources/PDFLibrarian/Models.swift" \
  "$ROOT_DIR/Sources/PDFLibrarian/AppLocalization.swift"
codesign --force --sign - --entitlements "$ROOT_DIR/Sources/PDFLibrarian/PDFLibrarian.entitlements" "$APP"
codesign --verify --deep --strict "$APP"
# No Homebrew path or Perl overrides; macOS provides the interpreter/core modules.
env -u PERL5LIB -u PERL5OPT PATH=/usr/bin:/bin "$APP/Contents/MacOS/MetadataBundleSmoke"
# Negative control: an incomplete library must never pass release validation.
rm "$APP/Contents/Resources/ExifTool/bin/lib/Image/ExifTool/PDF.pm"
if /bin/bash "$ROOT_DIR/scripts/verify_app_bundle.sh" "$APP" > "$TEST_DIR/incomplete.log" 2>&1; then
  echo 'FAIL: Incomplete dependency passed bundle validation' >&2
  exit 1
fi
echo 'PASS: incomplete ExifTool bundle rejected'
