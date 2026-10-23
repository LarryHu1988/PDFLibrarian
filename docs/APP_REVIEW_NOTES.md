# App Review notes — 1.5.0

PDF Librarian 1.5.0 is a native sandboxed macOS PDF metadata and filename organizer. No sign-in, payment, demo account, or external ExifTool installation is required.

Review workflow:
1. Import PDFs: click the import button and select one or more PDFs or a folder using NSOpenPanel.
2. Find Metadata: select a file, review the extracted bibliographic clues, and search public metadata sources. Availability varies by source; fields can also be edited manually.
3. Edit & Write: review/edit the 12 Dublin Core fields and their checkboxes. Click Review and write to compare metadata actually read from the selected PDF with frozen proposed values. The sheet identifies changed and cleared fields; confirm to write. Please use a disposable sample or copy for this test.
4. Save & Rename: inspect the editable filename and matching title/author/publisher/year/language colors. Use the native NSSavePanel to confirm the destination.

The sidebar resumes each file’s progress. The middle/detail divider is adjustable. Simplified Chinese and English are the only interface languages. Three appearance choices are available.

File access uses user-selected read/write permissions and security-scoped access. ExifTool 13.59 and its required Perl modules/licenses are bundled. Complete PDF files are not uploaded; requested online searches transmit bibliographic query clues to the chosen public sources. The app uses only exempt system HTTPS encryption.

Screenshots and previews use actual production application views with demonstration bibliographic data. No restricted books or PDF contents are distributed with the app.
