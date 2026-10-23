#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DISPLAY_NAME="PDF Librarian"
APP_EXECUTABLE="PDFLibrarian"
BUNDLE_ID="${BUNDLE_ID:-com.larry.pdflibrarian}"
LEGACY_VERSION="${VERSION:-}"
MARKETING_VERSION="${MARKETING_VERSION:-${LEGACY_VERSION:-1.5.0}}"
BUILD_VERSION="${BUILD_VERSION:-${LEGACY_VERSION:-2}}"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_DIR="${APP_DIR:-$ROOT_DIR/dist/${APP_DISPLAY_NAME}.app}"
EXECUTABLE="$BUILD_DIR/$APP_EXECUTABLE"
ICON_ICNS_SOURCE="$ROOT_DIR/Sources/PDFLibrarian/Resources/AppIcon.icns"
ICON_RESOURCE_NAME="AppIcon.icns"
ICON_PLIST_BLOCK=""

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp -X "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_EXECUTABLE"
chmod +x "$APP_DIR/Contents/MacOS/$APP_EXECUTABLE"

if [[ -f "$ICON_ICNS_SOURCE" ]]; then
  cp -X "$ICON_ICNS_SOURCE" "$APP_DIR/Contents/Resources/$ICON_RESOURCE_NAME"
  ICON_PLIST_BLOCK=$'    <key>CFBundleIconFile</key>\n    <string>AppIcon</string>'
else
  echo "WARNING: App icon not found at $ICON_ICNS_SOURCE"
  echo "Run scripts/generate_app_icons.sh to generate AppIcon.icns"
fi

/bin/bash "$ROOT_DIR/scripts/bundle_exiftool.sh" "$APP_DIR/Contents/Resources"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_DISPLAY_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_DISPLAY_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$MARKETING_VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_EXECUTABLE</string>
${ICON_PLIST_BLOCK}
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# iCloud/Finder can attach FinderInfo to a newly created .app directory.
# These two attributes are forbidden by codesign; touch only this build output.
xattr -r -d com.apple.FinderInfo "$APP_DIR" 2>/dev/null || true
xattr -r -d com.apple.ResourceFork "$APP_DIR" 2>/dev/null || true

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  codesign --force --deep --options runtime --sign "$SIGN_IDENTITY" "$APP_DIR"
  echo "Signed app with identity: $SIGN_IDENTITY"
else
  # Fallback to ad-hoc bundle signing to avoid broken linker-only signatures
  # that can trigger “app is damaged” on downloaded artifacts.
  codesign --force --deep --sign - "$APP_DIR"
  echo "Signed app with ad-hoc identity (-)"
fi

# Quick sanity check to ensure packaged app has a valid bundle signature.
/bin/bash "$ROOT_DIR/scripts/verify_app_bundle.sh" "$APP_DIR"

echo "App built: $APP_DIR"
echo "Version: $MARKETING_VERSION ($BUILD_VERSION)"
