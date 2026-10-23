import SwiftUI
import AppKit
import CoreGraphics

// Render the production MainView using a controlled state, without system screen capture.
// This is a visual fixture, not data included in the shipping application.
final class SnapshotWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

@main
struct ReleaseCapture {
    @MainActor static var fixtureDirectory = URL(fileURLWithPath: "/tmp")
    @MainActor static func main() throws {
        setbuf(stdout, nil)
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fixtureFolder = URL(fileURLWithPath: "/Users/Shared/PDF Librarian Demo 1.5.0", isDirectory: true)
        precondition(!FileManager.default.fileExists(atPath: fixtureFolder.path), "Demo directory already exists; will not overwrite it")
        try FileManager.default.createDirectory(at: fixtureFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: fixtureFolder) }
        fixtureDirectory = fixtureFolder
        var bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        for name in ["Semiconductor Power Devices_2018_en.pdf", "Introduction to Algorithms.pdf", "Fundamentals of Physics.pdf"] {
            let url = fixtureFolder.appendingPathComponent(name)
            let context = CGContext(url as CFURL, mediaBox: &bounds, nil)!
            context.beginPDFPage(nil); context.endPDFPage(); context.closePDF()
        }
        // Seed only the owned demonstration PDF so the review image shows real before/after values.
        try MetadataService().writeMetadata(fileURL: fixtureFolder.appendingPathComponent("Semiconductor Power Devices_2018_en.pdf"), entries: [
            "dc:title": "Semiconductor Power Devices", "dc:creator": "Josef Lutz", "dc:publisher": "Springer", "dc:date": "2018", "dc:language": "en"
        ])
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
        for language in AppLanguage.allCases {
            let locale = language == .english ? "en-US" : "zh-Hans"
            let folder = output.appendingPathComponent(locale, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for (index, step) in [(1, 1), (2, 2), (3, 3), (4, 4)] {
                let vm = step == 4 ? saveFixture(theme: .light) : fixture(theme: .light)
                vm.setLanguage(language)
                vm.status = language == .english ? "Demo library · Ready for review" : "演示书库 · 等待核对"
                try capture(vm, size: NSSize(width: 1440, height: 900), path: folder.appendingPathComponent(String(format: "%02d.png", index)), initialStep: step)
            }
            for (index, theme) in [(5, AppAppearanceMode.warm), (6, AppAppearanceMode.dark)] {
                let vm = saveFixture(theme: theme)
                vm.setLanguage(language)
                vm.status = language == .english ? "Demo library · Filename preview" : "演示书库 · 文件名预览"
                try capture(vm, size: NSSize(width: 1440, height: 900), path: folder.appendingPathComponent(String(format: "%02d.png", index)), initialStep: 4)
            }
            for step in 1...4 {
                let videoVM = step == 4 ? saveFixture(theme: .light) : fixture(theme: .light)
                videoVM.setLanguage(language)
                videoVM.status = language == .english ? "Demo library" : "演示书库"
                try capture(videoVM, size: NSSize(width: 1280, height: 720), path: folder.appendingPathComponent("video-\(step).png"), initialStep: step)
            }
            let vm = fixture(theme: .light)
            vm.setLanguage(language)
            vm.updateEditableDublinCoreValue("Semiconductor Power Devices — Second Edition", for: .title)
            vm.askWriteConfirmationForSelectedItem()
            let confirmation = MetadataWriteConfirmation(preview: vm.pendingWritePreview!, language: language, palette: WorkspacePalette.blue, onCancel: {}, onConfirm: {})
            try captureView(confirmation, size: NSSize(width: 880, height: 680), path: folder.appendingPathComponent("confirmation.png"))
        }
        print("PASS: release captures generated from production views; demo fixtures only")
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
