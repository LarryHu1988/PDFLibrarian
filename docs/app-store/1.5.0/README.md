# PDF Librarian 1.5.0 — Press Kit

中英文商店推广素材。`screenshots/zh-Hans` 与 `screenshots/en-US` 各含 6 张独立商业推广图，按 01–06 排序：整体工作区、批量导入、来源核对、写入前对比、分色命名、三种主题。图片为 2880×1800、RGB/sRGB PNG，可用于 Mac App Store 截屏栏位。`promotional/contact-*.jpg` 为总览，不用于商店上传。

Six commercial Mac App Store images per language, ordered 01–06: workspace, batch import, source comparison, write confirmation, color-matched naming, and three themes. Each image is a 2880×1800 RGB/sRGB PNG. Contact sheets in `promotional` are overview files rather than store uploads.

`previews` contains English and Simplified Chinese App Preview videos: 1920×1080, 30 fps, 29 seconds, H.264/AAC. `promotional` also includes hero posters and 1200×630 social cards. All app views come from production SwiftUI using demo bibliographic records. No book content, fabricated app controls, or third-party catalog logos are included. The confirmation sheet reads current metadata from an owned demo PDF before comparing proposed values.

Reproduce from the repository root with `scripts/capture_release.sh`, then `python3 scripts/generate_app_store_assets.py`. See `commercial-manifest.json` for exact copy and UI placement; see `docs/SCREENSHOT_SHOTLIST.md` for the sequence. Marketing imagery is separate from approval status: version 1.5.0 (2) is prepared in App Store Connect and has not been submitted for review.

© 2026 Larry Hu · [Website](https://larryhu.com/PDFLibrarian/)
