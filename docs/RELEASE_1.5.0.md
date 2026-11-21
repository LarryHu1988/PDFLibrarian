# PDF Librarian - 书目匠 1.5.0

Version: **1.5.0** · Build: **2** · macOS 13+ · Universal (Apple silicon and Intel)

## What changed

- A three-column workspace with a fixed workflow sidebar and adjustable content/detail panes.
- Four consistent steps: Import PDFs, Find Metadata, Edit & Write, Save & Rename.
- Multi-file import and per-file progress navigation.
- Current PDF metadata compared with frozen proposed values before writing; changed and cleared fields are visible.
- Five matching colors for core fields and filename components, with field icons and editable names.
- Blue, warm sage, and dark appearance; Simplified Chinese and English only.
- Bundled ExifTool 13.59 and required modules/licenses; no additional installation.
- Native sandbox file selection and save dialogs.

## Validation

Universal Release archive passed. Workspace state and production-view checks passed. Sandbox tests passed for 12 Dublin Core fields, Unicode/spaces, repeated writes, current XMP/PDF Info reads, long values, invalid inputs, complete ExifTool packaging, and preserving two PDF pages and their bodies.

## Release facts

- App Store Connect app: 6760351540.
- Version resource: e58ecb55-b032-4479-8e0c-f3f971d4ff2c.
- Build 2 resource: 31c5619c-64d6-4c39-826f-c8a1c64c0cdc, processing VALID.
- Build 0 was rejected by Apple error 90061 because macOS build numbers must exceed prior uploads. Build 2 was selected by the owner.
- Version 1.5.0 is available on the [Mac App Store](https://apps.apple.com/cn/app/id6760351540?mt=12).
- The owner selected local-only legacy cleanup. GitHub V1.0.0 release/assets/tag remain.

## Media

Six commercial 2880×1800 App Store images per locale, two 29-second 1920×1080 previews, bilingual promotional images, and updated website images. Store compositions combine large benefit-led headlines, understated backgrounds and real UI details. All product imagery comes from production SwiftUI views using demo bibliographic data. The write-confirmation demonstration compares metadata read from an owned demo PDF with proposed changes. Video camera edits are authored in HyperFrames; no book contents are included.

## Installation

For direct installation, download the GitHub release ZIP signed with Developer ID. Apple accepted notarization submission `47f8b83c-2a69-4050-903f-929fa7c49109`; its app has a validated stapled ticket and passes Gatekeeper as `Notarized Developer ID`. See GitHub release attachments for distribution files. This notarization is separate from App Store review.
