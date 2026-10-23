#!/usr/bin/env bash
set -euo pipefail

# Used by BOTH Xcode (before code signing) and the SwiftPM app packager.
# Build offline from pinned upstream source, never from the builder's Homebrew.
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=13.59
SHA256=87d3317882fdae9cb4dcfe57a96a378d0132ffc02c731315bf128b19ddcf7aac
ARCHIVE="$ROOT_DIR/vendor/exiftool/Image-ExifTool-$VERSION.tar.gz"
RESOURCES_DIR="${1:?Usage: bundle_exiftool.sh APP_CONTENTS_RESOURCES_DIRECTORY}"
DEST="$RESOURCES_DIR/ExifTool"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "error: Missing pinned ExifTool source: $ARCHIVE" >&2
  exit 1
fi
ACTUAL_SHA256="$(/usr/bin/shasum -a 256 "$ARCHIVE" | /usr/bin/awk '{print $1}')"
if [[ "$ACTUAL_SHA256" != "$SHA256" ]]; then
  echo "error: ExifTool source checksum mismatch. Restore the pinned vendor archive." >&2
  exit 1
fi

mkdir -p "$RESOURCES_DIR"
rm -rf "$DEST"
mkdir -p "$DEST/bin"
/usr/bin/tar -xzf "$ARCHIVE" -C "$DEST/bin" --strip-components=1 \
  "exiftool-$VERSION/exiftool" "exiftool-$VERSION/lib"
/usr/bin/tar -xOf "$ARCHIVE" "exiftool-$VERSION/README" > "$DEST/UPSTREAM-README.txt"
/usr/bin/tar -xOf "$ARCHIVE" "exiftool-$VERSION/LICENSE" > "$DEST/UPSTREAM-LICENSE.txt"
cp "$ROOT_DIR/vendor/exiftool/ARTISTIC.txt" "$DEST/ARTISTIC.txt"
cp "$ROOT_DIR/vendor/exiftool/NOTICE.txt" "$DEST/NOTICE.txt"
chmod -R u+rwX,go+rX "$DEST"
chmod 755 "$DEST/bin/exiftool"
printf '%s\n' "$VERSION" > "$DEST/VERSION"

# Load the PDF writer, not just the CLI version (which can pass with missing libs).
env -u PERL5LIB -u PERL5OPT /usr/bin/perl -I "$DEST/bin/lib" \
  -MImage::ExifTool::PDF -MImage::ExifTool::XMP -MCompress::Zlib -MDigest::MD5 -e 1
ACTUAL_VERSION="$(env -u PERL5LIB -u PERL5OPT /usr/bin/perl "$DEST/bin/exiftool" -config '' -ver)"
[[ "$ACTUAL_VERSION" == "$VERSION" ]] || { echo "error: ExifTool version mismatch" >&2; exit 1; }
echo "Bundled ExifTool $VERSION (script, complete libraries, licenses)"
