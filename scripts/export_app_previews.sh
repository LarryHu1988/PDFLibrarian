#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for locale in en-US zh-Hans; do
  input="$ROOT/dist/1.5.0/video-masters/$locale.mp4"
  output="$ROOT/dist/1.5.0/$locale-app-preview.mp4"
  ffmpeg -y -hide_banner -loglevel error -i "$input" -f lavfi -i anullsrc=r=48000:cl=stereo -map 0:v:0 -map 1:a:0 -c:v libx264 -preset fast -profile:v high -level:v 4.0 -pix_fmt yuv420p -r 30 -b:v 10M -minrate 10M -maxrate 10M -bufsize 20M -x264-params nal-hrd=cbr:force-cfr=1 -c:a aac -b:a 256k -ac 2 -ar 48000 -t 29 -movflags +faststart "$output"
  cp "$output" "$ROOT/docs/app-store/1.5.0/previews/$locale.mp4"
done
