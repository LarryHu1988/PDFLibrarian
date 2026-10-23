#!/usr/bin/env bash
set -euo pipefail
APP="${1:?Usage: verify_app_bundle.sh BUILT_APP_PATH}"
TOOL_DIR="$APP/Contents/Resources/ExifTool"
for file in bin/exiftool bin/lib/Image/ExifTool.pm bin/lib/Image/ExifTool/PDF.pm bin/lib/Image/ExifTool/XMP.pm ARTISTIC.txt NOTICE.txt VERSION; do
  if [[ ! -s "$TOOL_DIR/$file" ]]; then
    echo "error: Incomplete ExifTool bundle: $TOOL_DIR/$file" >&2
    exit 1
  fi
done
[[ -x "$TOOL_DIR/bin/exiftool" ]] || { echo 'error: ExifTool is not executable' >&2; exit 1; }
env -i PATH=/usr/bin:/bin /usr/bin/perl -I "$TOOL_DIR/bin/lib" \
  -MImage::ExifTool::PDF -MImage::ExifTool::XMP -MCompress::Zlib -MDigest::MD5 -e 1
VERSION="$(env -i PATH=/usr/bin:/bin /usr/bin/perl "$TOOL_DIR/bin/exiftool" -config '' -ver)"
[[ "$VERSION" == "$(cat "$TOOL_DIR/VERSION")" ]] || { echo 'error: ExifTool version mismatch' >&2; exit 1; }
codesign --verify --deep --strict "$APP"
echo "Verified signed app and bundled ExifTool $VERSION: $APP"
