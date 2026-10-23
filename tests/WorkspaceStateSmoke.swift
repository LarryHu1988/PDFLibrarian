import Foundation
import CoreGraphics

@main
struct WorkspaceStateSmoke {
    @MainActor static func main() throws {
        let defaults = UserDefaults.standard
        let keys = ["app.appearance.mode", "app.language.code"]
        let saved = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, saved) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
        let probe = FileManager.default.temporaryDirectory.appendingPathComponent("PDFLibrarian-info-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: probe) }
        var bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let context = CGContext(probe as CFURL, mediaBox: &bounds, nil)!
        for _ in 0..<2 { context.beginPDFPage(nil); context.endPDFPage() }
        context.closePDF()
        let details = PDFSelectionDetails.read(probe)
        precondition(details.pages == 2 && (details.bytes ?? 0) > 0 && details.modified != nil, "Selected PDF details were not read correctly")
        let importFolder = FileManager.default.temporaryDirectory.appendingPathComponent("PDFLibrarian-multiselect-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: importFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: importFolder) }
        let firstPDF = importFolder.appendingPathComponent("一号 PDF.pdf")
        let secondPDF = importFolder.appendingPathComponent("Second.PDF")
        try FileManager.default.copyItem(at: probe, to: firstPDF)
        try FileManager.default.copyItem(at: probe, to: secondPDF)
        let importer = MainViewModel()
        importer.selectSources([firstPDF, secondPDF])
        importer.loadPDFsFromSource()
        precondition(importer.items.count == 2 && !importer.statusIsError, "Multiple selected PDFs were not imported")
        importer.selectSources([importFolder, firstPDF])
        importer.loadPDFsFromSource()
        precondition(importer.items.count == 2 && Set(importer.items.map(\.url)).count == 2, "Overlapping folder/file selection duplicated a PDF")
        let preservedIDs = importer.items.map(\.id)
        let invalid = importFolder.appendingPathComponent("invalid.txt")
        try Data("not a PDF".utf8).write(to: invalid)
        importer.selectSources([invalid])
        importer.loadPDFsFromSource()
        precondition(importer.statusIsError && importer.items.map(\.id) == preservedIDs, "Invalid import destroyed the prior batch")
        for language in AppLanguage.allCases {
            precondition(!AppLocalization.text(.validationSources, language: language).contains("%@"))
            precondition(!AppLocalization.text(.chipValidated, language: language).contains("%@"))
        }
        let vm = MainViewModel()
        vm.loadPDFsFromSource()
        precondition(vm.statusIsError, "Missing input was shown as success")
        let hint = PDFSearchHint(fileNameTitle: "Test", extractedTitle: "Test", snippet: "", isbn: nil, doi: nil, queryCandidates: ["Test"])
        let a = BookMetadataCandidate(kind: .book, title: "First source", subtitle: "", authors: ["Author"], publisher: "Publisher", publishedYear: "2018", language: "en", isbn: "9783319709178", doi: "", source: "Google Books", sourceURL: "https://books.google.com/", validatedBy: [], confidence: 98)
        var b = a
        b.title = "Second source"
        // Distinct candidates need distinct IDs, so create the alternate record explicitly.
        let alternate = BookMetadataCandidate(kind: .book, title: b.title, subtitle: "", authors: b.authors, publisher: b.publisher, publishedYear: b.publishedYear, language: b.language, isbn: b.isbn, doi: "", source: "Open Library", sourceURL: "https://openlibrary.org/", validatedBy: [], confidence: 96)
        var first = PDFWorkItem(url: firstPDF, hint: hint)
        first.candidates = [a, alternate]; first.stage = .searched
        var second = PDFWorkItem(url: secondPDF, hint: hint)
        second.candidates = [a]; second.stage = .searched
        vm.items = [first, second]
        vm.selectItem(first.id)
        vm.chooseCandidate(a.id, for: first.id)
        vm.updateEditableDublinCoreValue("User title", for: .title)
        vm.chooseCandidate(alternate.id, for: first.id)
        precondition(vm.editableDublinCoreValues[.title] == "Second source")
        vm.chooseCandidate(a.id, for: first.id)
        precondition(vm.editableDublinCoreValues[.title] == "User title", "Switching candidates lost edits")
        vm.selectItem(second.id)
        vm.chooseCandidate(a.id, for: second.id)
        precondition(vm.editableDublinCoreValues[.title] == "First source", "Different files shared an edit cache")
        vm.selectItem(first.id)
        precondition(vm.editableDublinCoreValues[.title] == "User title")
        try MetadataService().writeMetadata(fileURL: firstPDF, entries: ["dc:title": "On-disk title", "dc:publisher": "Old publisher"])
        let beforePreview = try Data(contentsOf: firstPDF)
        vm.selectedDublinCoreFields = [.title]
        vm.askWriteConfirmationForSelectedItem()
        precondition(vm.showWriteConfirmation && vm.pendingWriteSummary.contains("User title"))
        precondition(vm.pendingWritePreview?.rows.count == 2 && vm.pendingWritePreview?.selectedCount == 1 && vm.pendingWritePreview?.modifiedCount == 2)
        precondition(vm.pendingWritePreview?.rows[0].originalValue == "On-disk title" && vm.pendingWritePreview?.rows[0].proposedValue == "User title", "Preview did not read the actual file metadata")
        precondition(vm.pendingWritePreview?.rows[1].field == .publisher && vm.pendingWritePreview?.rows[1].isRemoval == true && vm.pendingWritePreview?.rows[1].isSelectedForWrite == false, "Old unchecked metadata deletion was not shown")
        let afterPreview = try Data(contentsOf: firstPDF)
        precondition(afterPreview == beforePreview, "Preview modified the PDF")
        vm.updateEditableDublinCoreValue("Later edit", for: .title)
        precondition(vm.pendingWritePreview?.rows[0].proposedValue == "User title", "Confirmation snapshot mutated after opening")
        vm.updateEditableDublinCoreValue("User title", for: .title)
        precondition(!vm.pendingWriteSummary.contains("dc:publisher"), "Unchecked fields entered the write preview")
        vm.cancelWriteConfirmation()
        precondition(vm.pendingWriteSummary.isEmpty && vm.pendingWritePreview == nil && !vm.showWriteConfirmation)
        vm.updateEditableDublinCoreValue("On-disk title", for: .title)
        vm.askWriteConfirmationForSelectedItem()
        precondition(vm.pendingWritePreview?.rows[0].isModified == false, "Equal file/current value incorrectly highlighted")
        vm.cancelWriteConfirmation()
        vm.updateEditableDublinCoreValue("User title", for: .title)
        let realURL = vm.items[0].url
        vm.items[0].url = importFolder.appendingPathComponent("missing.pdf")
        vm.askWriteConfirmationForSelectedItem()
        precondition(vm.statusIsError && !vm.showWriteConfirmation && vm.pendingWritePreview == nil, "Failed metadata read fabricated a comparison")
        vm.items[0].url = realURL
        vm.updateEditableDublinCoreValue(" ", for: .title)
        vm.askWriteConfirmationForSelectedItem()
        precondition(vm.statusIsError && !vm.showWriteConfirmation, "All-empty write offered misleading confirmation")
        vm.updateEditableDublinCoreValue("User title", for: .title)
        let filename = "半导体.Power.Devices_Lutz_Springer_2018_en.PDF"
        let segments = RenameFileNameSegment.segments(for: filename)
        precondition(segments.map(\.value).joined() == filename && segments.compactMap(\.field) == DublinCoreField.basicFields)
        precondition(RenameFileNameSegment.segments(for: "custom_title.pdf").allSatisfy { $0.field == nil })
        vm.showWriteConfirmation = false
        vm.selectedDublinCoreFields = []
        vm.askWriteConfirmationForSelectedItem()
        precondition(!vm.showWriteConfirmation, "Empty selection offered a write")
        vm.items[0].stage = .written
        vm.renamePrompt = RenamePromptState(itemID: first.id, suggestedFileName: "first.pdf", editableFileName: "my-first.pdf")
        vm.selectItem(second.id)
        precondition(vm.renamePrompt == nil, "Another file inherited a pending rename")
        vm.items[1].stage = .written
        vm.renamePrompt = RenamePromptState(itemID: second.id, suggestedFileName: "second.pdf", editableFileName: "my-second.pdf")
        vm.selectItem(first.id)
        precondition(vm.renamePromptFileName == "my-first.pdf", "Pending filename was lost")
        vm.skipRenameForPrompt()
        precondition(vm.items[0].stage == .renameSkipped)
        vm.selectItem(second.id)
        precondition(vm.saveItems.count == 2, "Ready-to-save queue lost a completed or pending file")
        precondition(vm.renamePromptFileName == "my-second.pdf", "Skipping one file cleared another file")
        vm.selectItem(first.id)
        precondition(vm.renamePrompt == nil)
        vm.items[0].stage = .failed
        precondition(vm.currentStep == 3, "Write errors sent the user away from the editor")
        let navigation = WorkspaceNavigation()
        for (stage, expectedStep) in [(PDFWorkflowStage.loaded, 2), (.searched, 3), (.written, 4), (.renamed, 4), (.renameSkipped, 4), (.failed, 3)] {
            vm.items[0].stage = stage
            navigation.resumeFile(first.id, using: vm)
            precondition(navigation.step == expectedStep && vm.selectedItemID == first.id, "Sidebar file did not resume its pending workflow")
        }
        let priorSelection = vm.selectedItemID
        navigation.resumeFile(UUID(), using: vm)
        precondition(vm.selectedItemID == priorSelection, "Unknown file cleared the selected document")
        precondition(AppLanguage.allCases.count == 2)
        precondition(AppLanguage.from(code: "en-US") == .english && AppLanguage.from(code: "zh-CN") == .simplifiedChinese)
        for oldCode in ["es", "hi", "ar", "fr", "pt", "ru", "ja", "de"] {
            defaults.set(oldCode, forKey: "app.language.code")
            precondition(AppLanguage.allCases.contains(MainViewModel().language), "Removed language preference was not migrated")
            precondition(AppLanguage.from(code: oldCode) == nil)
        }
        for language in AppLanguage.allCases {
            vm.setLanguage(language)
            precondition(MainViewModel().language == language, "Language did not persist")
        }
        for theme in AppAppearanceMode.allCases {
            vm.setAppearanceMode(theme)
            precondition(MainViewModel().appearanceMode == theme, "Theme did not persist")
        }
        print("PASS: candidate/file edit isolation, checked-only confirmation, empty-selection guard, per-file rename recovery, error navigation, sidebar workflow resume, two-language and three-theme persistence, multi-PDF import/deduplication, structured change preview")
    }
}
