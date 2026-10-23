# PDF Librarian 1.5.0 design QA

Production workspace and metadata tests passed on 2026-10-24. Chinese and English release captures cover all four steps and all three themes at 1440×900 points (2880×1800 pixels). Minimum-size layout, sidebar progress, native split resizing, frozen write previews, changed/clear rows, filename colors, and actual confirmation-sheet presentation are covered by the workspace test harness.

Commercial App Store images: `docs/app-store/1.5.0/screenshots`, six per locale at 2880×1800, RGB/sRGB. Both contact sheets and enlarged details were inspected for copy, clipping, brand placement, accurate native UI, current-versus-proposed values, and the five matching field colors. Both locales pass `asc screenshots validate` with zero errors and warnings. The deterministic renderer and copy/placement manifest are retained. Raw view captures are source material rather than the final store designs. Current generated QA reports remain local under `dist/1.5.0`. Historical visual variants were moved to Trash by the owner’s request.

Browser tests cover bilingual website copy, images, responsive widths, and workflow preview interaction. Real pointer testing of the macOS application was not re-run for this release; native view/state harnesses cover the production UI.
