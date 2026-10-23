#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT_NAME="PDFLibrarian"
SCHEME_NAME="PDFLibrarian"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
INFO_PLIST="$ROOT_DIR/Sources/PDFLibrarian/Info.plist"
XCODE_DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

marketing_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
build_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")"
archive_suffix="$marketing_version"
if [[ "$build_version" != "$marketing_version" ]]; then
  archive_suffix="${marketing_version}-build-${build_version}"
fi

if [[ ! -d "$PROJECT_FILE" ]]; then
  echo "Missing $PROJECT_FILE, run: xcodegen generate"
  exit 1
fi

if [[ "${DEVELOPER_DIR:-}" == "" && -d "$XCODE_DEVELOPER_DIR" ]]; then
  export DEVELOPER_DIR="$XCODE_DEVELOPER_DIR"
fi

TEAM_ID="${TEAM_ID:-}"
EXPORT_METHOD="${EXPORT_METHOD:-app-store-connect}"
ARCHIVE_PATH="$ROOT_DIR/dist/${PROJECT_NAME}-${archive_suffix}.xcarchive"
EXPORT_PATH="$ROOT_DIR/dist/xcode-export-${archive_suffix}"
EXPORT_PLIST="$ROOT_DIR/dist/ExportOptions.plist"

mkdir -p "$ROOT_DIR/dist"

if ! xcrun xcodebuild -version >/dev/null 2>&1; then
  echo "xcodebuild is unavailable. Make sure full Xcode is installed."
  echo "Recommended fix:"
  echo "  sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

cat > "$EXPORT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>$EXPORT_METHOD</string>
  <key>destination</key>
  <string>export</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
</dict>
</plist>
PLIST

if [[ -n "$TEAM_ID" ]]; then
  xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    -allowProvisioningUpdates \
    archive
else
  xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    archive
fi

/bin/bash "$ROOT_DIR/scripts/verify_app_bundle.sh" "$ARCHIVE_PATH/Products/Applications/PDF Librarian.app"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_PATH" \
  -allowProvisioningUpdates

echo "Archive: $ARCHIVE_PATH"
echo "Export: $EXPORT_PATH"
echo "Version: $marketing_version ($build_version)"
