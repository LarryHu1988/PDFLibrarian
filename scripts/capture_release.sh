#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="${1:-$ROOT_DIR/dist/1.5.0/captures}"
PROBE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/PDFLibrarian-release-capture.XXXXXX")"
trap 'rm -rf "$PROBE_DIR"' EXIT
cp "$ROOT_DIR/Sources/PDFLibrarian/Resources/AppIcon.icns" "$PROBE_DIR/AppIcon.icns"
/bin/bash "$ROOT_DIR/scripts/bundle_exiftool.sh" "$PROBE_DIR"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SOURCES=()
for source in "$ROOT_DIR"/Sources/PDFLibrarian/*.swift; do
  [[ "$(basename "$source")" == PDFLibrarianApp.swift ]] && continue
  SOURCES+=("$source")
done
xcrun swiftc -target "$(uname -m)-apple-macos13.0" -parse-as-library "${SOURCES[@]}" "$ROOT_DIR/scripts/ReleaseCapture.swift" -o "$PROBE_DIR/ReleaseCapture"
"$PROBE_DIR/ReleaseCapture" "$OUTPUT"
