# Release media — 1.5.0

Each language has six commercial App Store compositions at 2880×1800, RGB/sRGB. Each combines exact bilingual promotional copy, a restrained glass-like background, and unchanged production UI captures:

1. A clearer home for every PDF — the full workspace.
2. Import more. Keep your place — multi-file import and per-file sidebar progress.
3. Compare first. Choose with care — source records and bibliographic details.
4. See every change. Before you write — the actual current-versus-proposed confirmation sheet.
5. Five fields. One clear name — matching metadata and filename colors.
6. Three themes. Your kind of calm — blue, warm sage, and dark.

`docs/app-store/1.5.0/screenshots` contains the final marketing images uploaded to the store screenshot slots. Raw native captures remain local production sources under `dist/1.5.0/captures`. `commercial-manifest.json` records the exact copy and native-image placement. No generated or recreated app controls are used. The confirmation demonstration reads seeded metadata from a temporary owned demo PDF.

The two previews are 1920×1080 at 30 fps, 29 seconds. They show the four steps, current-versus-proposed metadata confirmation, and three themes. Native production views are rendered with controlled demo data; the camera edit is authored in HyperFrames. These are application-view captures rather than a desktop recording.

Install `scripts/requirements-media.txt`, run `scripts/capture_release.sh`, then `python3 scripts/generate_app_store_assets.py`. The latter also runs `scripts/generate_store_commercial.py --install`, ensuring store assets retain their commercial layouts. Video source is in `videos/app-preview-1.5.0`.
