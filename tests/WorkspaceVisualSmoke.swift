import SwiftUI
import AppKit
import CoreGraphics

// Render the production MainView using a controlled state, without system screen capture.
// This is a visual fixture, not data included in the shipping application.
final class SnapshotWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

@main
struct WorkspaceVisualSmoke {
    @MainActor static var fixtureDirectory = URL(fileURLWithPath: "/tmp")
    @MainActor static func main() throws {
        setbuf(stdout, nil)
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fixtureFolder = output.appendingPathComponent("fixtures", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtureFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: fixtureFolder) }
        fixtureDirectory = fixtureFolder
        var bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        for name in ["Semiconductor Power Devices_2018_en.pdf", "Introduction to Algorithms.pdf", "Fundamentals of Physics.pdf"] {
            let url = fixtureFolder.appendingPathComponent(name)
            let context = CGContext(url as CFURL, mediaBox: &bounds, nil)!
            context.beginPDFPage(nil); context.endPDFPage(); context.closePDF()
        }
        let defaults = UserDefaults.standard
        let keys = ["app.appearance.mode", "app.language.code"]
        let saved = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, saved) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        for theme in AppAppearanceMode.allCases {
            let vm = fixture(theme: theme)
            try capture(vm, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("editor-\(theme.rawValue).png"))
        }
        let narrow = fixture(theme: .warm)
        try capture(narrow, size: NSSize(width: 1060, height: 720), path: output.appendingPathComponent("editor-minimum.png"))
        let english = fixture(theme: .light)
        english.setLanguage(.english)
        try capture(english, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("editor-english.png"))
        let empty = MainViewModel()
        empty.setLanguage(.simplifiedChinese)
        empty.setAppearanceMode(.light)
        try capture(empty, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("empty.png"))
        let search = fixture(theme: .light)
        try capture(search, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("lookup.png"), initialStep: 2)
        let save = saveFixture(theme: .warm)
        try capture(save, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("save.png"))
        try capture(saveFixture(theme: .dark), size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("save-dark.png"))
        try capture(saveFixture(theme: .light), size: NSSize(width: 1060, height: 720), path: output.appendingPathComponent("save-minimum.png"))
        let editedName = saveFixture(theme: .light)
        try capture(editedName, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("save-edited-name.png"), afterDisplay: {
            editedName.updateRenamePromptFileName("新标题_新作者_新出版社_2026_zh.pdf")
        })
        let customName = saveFixture(theme: .warm)
        try capture(customName, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("save-custom-name.png"), afterDisplay: {
            customName.updateRenamePromptFileName("Custom archive.pdf")
        })
        let loading = fixture(theme: .dark)
        loading.isSearching = true
        loading.status = "正在检索元数据…"
        try capture(loading, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("loading.png"))
        empty.loadPDFsFromSource()
        try capture(empty, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("error.png"))
        let files = fixture(theme: .light)
        try capture(files, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("files.png"), initialStep: 1)
        let fileNavigation = WorkspaceNavigation(step: 1)
        try capture(files, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("files-selected-other.png"), navigation: fileNavigation, afterDisplay: {
            files.selectItem(files.items[1].id)
        })
        precondition(fileNavigation.step == 1, "Selecting a file unexpectedly advanced the workflow")
        let lookupNavigation = WorkspaceNavigation(step: 2)
        let lookup = fixture(theme: .warm)
        try capture(lookup, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("lookup-other-candidate.png"), navigation: lookupNavigation, afterDisplay: {
            lookup.chooseCandidate(lookup.items[0].candidates[1].id, for: lookup.items[0].id)
        })
        precondition(lookupNavigation.step == 2, "Selecting a result skipped its detail/preparation step")
        let searchNavigation = WorkspaceNavigation(step: 2)
        let searched = fixture(theme: .light)
        let results = searched.items[0].candidates
        searched.items[0].candidates = []
        searched.items[0].selectedCandidateID = nil
        searched.items[0].stage = .loaded
        try capture(searched, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("lookup-completed.png"), navigation: searchNavigation, afterDisplay: {
            searched.items[0].candidates = results
            searched.items[0].stage = .searched
            searched.chooseCandidate(results[0].id, for: searched.items[0].id)
        })
        precondition(searchNavigation.step == 2, "Search completion unexpectedly opened the field editor")
        let fieldNavigation = WorkspaceNavigation(step: 3)
        let fields = fixture(theme: .warm)
        try capture(fields, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("field-author.png"), navigation: fieldNavigation, afterDisplay: {
            fieldNavigation.field = .creator
        })
        let sidebarNavigation = WorkspaceNavigation(step: 1)
        let sidebarFiles = fixture(theme: .light)
        try capture(sidebarFiles, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("sidebar-resume-file.png"), navigation: sidebarNavigation, afterDisplay: {
            sidebarNavigation.resumeFile(sidebarFiles.items[2].id, using: sidebarFiles)
        })
        precondition(sidebarNavigation.step == 4 && sidebarFiles.selectedItemID == sidebarFiles.items[2].id, "Sidebar file did not resume its own workflow")
        let wideNavigation = WorkspaceNavigation(step: 3)
        try capture(fixture(theme: .light), size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("resized-content-wide.png"), navigation: wideNavigation, splitPositions: [650], afterResize: {
            wideNavigation.step = 2
        })
        let narrowNavigation = WorkspaceNavigation(step: 3)
        let resized = fixture(theme: .dark)
        try capture(resized, size: NSSize(width: 1440, height: 1024), path: output.appendingPathComponent("resized-detail-narrow.png"), navigation: narrowNavigation, splitPositions: [840], afterResize: {
            resized.setAppearanceMode(.warm)
            narrowNavigation.field = .creator
        })
        for theme in AppAppearanceMode.allCases {
            let vm = fixture(theme: theme)
            vm.selectedDublinCoreFields = Set(DublinCoreField.allCases)
            vm.updateEditableDublinCoreValue("Semiconductor Power Devices — Second Edition", for: .title)
            vm.updateEditableDublinCoreValue("Josef Lutz; Heinrich Schlangenotto; Uwe Scheuermann; Rik De Doncker", for: .creator)
            let onDisk = vm.dublinCoreValueMap(for: vm.items[0].candidates[0], fileURL: vm.items[0].url)
            try MetadataService().writeMetadata(fileURL: vm.items[0].url, entries: Dictionary(uniqueKeysWithValues: onDisk.map { ($0.key.rawValue, $0.value) }))
            vm.askWriteConfirmationForSelectedItem()
            guard let preview = vm.pendingWritePreview else { fatalError("Write preview missing") }
            for row in preview.rows where row.isModified { print("DIFF: \(row.field.rawValue) [\(row.originalValue)] → [\(row.proposedValue)]") }
            precondition(preview.modifiedCount == 2 && preview.selectedCount == 12 && preview.rows.count == 12)
            let confirmation = MetadataWriteConfirmation(preview: preview, language: .simplifiedChinese, palette: theme.palette, onCancel: {}, onConfirm: {})
                .environment(\.colorScheme, theme.preferredColorScheme)
            try captureView(confirmation, size: NSSize(width: 880, height: 680), path: output.appendingPathComponent("write-confirmation-\(theme.rawValue).png"), colorScheme: theme.preferredColorScheme)
        }
        let englishReview = fixture(theme: .light)
        englishReview.setLanguage(.english)
        englishReview.updateEditableDublinCoreValue("Edited title", for: .title)
        englishReview.askWriteConfirmationForSelectedItem()
        let englishConfirmation = MetadataWriteConfirmation(preview: englishReview.pendingWritePreview!, language: .english, palette: WorkspacePalette.blue, onCancel: {}, onConfirm: {})
        try captureView(englishConfirmation, size: NSSize(width: 880, height: 680), path: output.appendingPathComponent("write-confirmation-english.png"))
        let presented = fixture(theme: .warm)
        presented.updateEditableDublinCoreValue("Reviewed title", for: .title)
        try capture(presented, size: NSSize(width: 1060, height: 720), path: output.appendingPathComponent("write-sheet-presented.png"), initialStep: 3, afterDisplay: {
            presented.askWriteConfirmationForSelectedItem()
        }, captureSheet: true)
        print("PASS: progressive file/result/field navigation and fixed sidebar and native content/detail divider")
        print("PASS: production SwiftUI captures written to \(output.path)")
    }

    @MainActor static func saveFixture(theme: AppAppearanceMode) -> MainViewModel {
        let vm = fixture(theme: theme)
        let values = vm.dublinCoreValueMap(for: vm.items[0].candidates[0], fileURL: vm.items[0].url)
        let name = BookRenameService().suggestedFileName(forDublinCore: Dictionary(uniqueKeysWithValues: values.map { ($0.key.rawValue, $0.value) }))
        vm.items[0].stage = .written
        vm.renamePrompt = RenamePromptState(itemID: vm.items[0].id, suggestedFileName: name, editableFileName: name)
        return vm
    }

    @MainActor static func fixture(theme: AppAppearanceMode) -> MainViewModel {
        let vm = MainViewModel()
        vm.setLanguage(.simplifiedChinese)
        vm.setAppearanceMode(theme)
        let hint = PDFSearchHint(fileNameTitle: "Semiconductor Power Devices", extractedTitle: "Semiconductor Power Devices", snippet: "Physics, Characteristics, Reliability", isbn: "9783319709178", doi: nil, queryCandidates: ["Semiconductor Power Devices"])
        var item = PDFWorkItem(url: fixtureDirectory.appendingPathComponent("Semiconductor Power Devices_2018_en.pdf"), hint: hint)
        item.candidates = zip(["Google Books", "Open Library", "Library of Congress"], [98, 96, 92]).map { source, confidence in
            BookMetadataCandidate(kind: .book, title: "Semiconductor Power Devices", subtitle: "", authors: ["Josef Lutz", "Heinrich Schlangenotto", "Uwe Scheuermann", "Rik De Doncker"], publisher: "Springer", publishedYear: "2018", language: "en", isbn: "978-3-319-70917-8", doi: "", source: source, sourceURL: "https://books.google.com/", validatedBy: ["Google Books", "Open Library"], confidence: confidence)
        }
        item.stage = .searched
        var second = PDFWorkItem(url: fixtureDirectory.appendingPathComponent("Introduction to Algorithms.pdf"), hint: hint)
        second.stage = .loaded
        var third = PDFWorkItem(url: fixtureDirectory.appendingPathComponent("Fundamentals of Physics.pdf"), hint: hint)
        third.stage = .renamed
        vm.items = [item, second, third]
        vm.selectItem(item.id)
        vm.chooseCandidate(item.candidates[0].id, for: item.id)
        vm.status = "检索完成 · 等待写入"
        return vm
    }

    @MainActor static func findSplit(in view: NSView) -> NSSplitView? {
        if let split = view as? NSSplitView, split.isVertical, split.subviews.count == 2 { return split }
        for child in view.subviews { if let split = findSplit(in: child) { return split } }
        return nil
    }

    @MainActor static func captureView<V: View>(_ root: V, size: NSSize, path: URL, colorScheme: ColorScheme = .light) throws {
        let host = NSHostingView(rootView: root)
        let window = SnapshotWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.setContentSize(size)
        window.makeKeyAndOrderFront(nil)
        window.setFrame(NSRect(origin: .zero, size: size), display: true)
        host.setFrameSize(size)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("Cannot allocate view bitmap") }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot encode capture") }
        try png.write(to: path)
        print("CAPTURE: \(path.lastPathComponent) \(bitmap.pixelsWide)x\(bitmap.pixelsHigh)")
        window.close()
    }

    @MainActor static func capture(_ vm: MainViewModel, size: NSSize, path: URL, initialStep: Int? = nil, navigation: WorkspaceNavigation? = nil, splitPositions: [CGFloat]? = nil, afterDisplay: (() -> Void)? = nil, afterResize: (() -> Void)? = nil, captureSheet: Bool = false) throws {
        let root = MainView(viewModel: vm, initialStep: initialStep, navigation: navigation)
        let host = NSHostingView(rootView: root)
        let window = SnapshotWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.setContentSize(size)
        window.makeKeyAndOrderFront(nil)
        window.setFrame(NSRect(origin: .zero, size: size), display: true)
        host.setFrameSize(size)
        window.makeFirstResponder(host)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))
        if let afterDisplay {
            afterDisplay()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
        }
        guard let split = findSplit(in: host) else { fatalError("Production workspace did not expose its content/detail split view") }
        let sidebarExtent = split.convert(.zero, to: host).x
        precondition(abs(sidebarExtent - WorkspaceLayout.sidebarWidth - 1) < 1, "Sidebar width changed or participates in the draggable split")
        if let positions = splitPositions {
            let original = split.subviews.map { $0.frame.width }
            split.setPosition(positions[0], ofDividerAt: 0)
            split.adjustSubviews()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
            let widths = split.subviews.map { $0.frame.width }
            precondition(zip(original, widths).contains { abs($0 - $1) > 30 }, "Dragging dividers did not resize columns")
            precondition(widths[0] >= 279 && widths[1] >= 319, "Divider resizing violated usable minimum widths")
            precondition(abs(split.convert(.zero, to: host).x - sidebarExtent) < 1, "Resizing content moved the fixed sidebar")
            if let afterResize {
                afterResize()
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
                let updated = split.subviews.map { $0.frame.width }
                precondition(zip(widths, updated).allSatisfy { abs($0 - $1) < 1 }, "Updating workflow or theme reset the divider positions")
            }
            print("SPLIT: \(path.lastPathComponent) widths=\(widths)")
        }
        if captureSheet {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            guard let sheet = window.sheets.first, let sheetView = sheet.contentView else { fatalError("Production confirmation was not presented as a sheet") }
            precondition(sheetView.bounds.width >= 880 && sheetView.bounds.height >= 680 && sheetView.bounds.height <= 720, "Confirmation sheet did not fit the minimum window")
            sheetView.layoutSubtreeIfNeeded()
            guard let bitmap = sheetView.bitmapImageRepForCachingDisplay(in: sheetView.bounds) else { fatalError("Cannot allocate sheet bitmap") }
            sheetView.cacheDisplay(in: sheetView.bounds, to: bitmap)
            guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot encode sheet capture") }
            try png.write(to: path)
            print("SHEET: \(sheetView.bounds.size); CAPTURE: \(path.lastPathComponent)")
            vm.cancelWriteConfirmation()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
            precondition(window.sheets.isEmpty && vm.pendingWritePreview == nil, "Cancel did not dismiss the sheet and clear its snapshot")
            window.close()
            return
        }
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("Cannot allocate view bitmap") }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot encode capture") }
        try png.write(to: path)
        print("CAPTURE: \(path.lastPathComponent) \(bitmap.pixelsWide)x\(bitmap.pixelsHigh)")
        window.close()
    }
}
