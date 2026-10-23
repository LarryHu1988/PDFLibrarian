import SwiftUI
import AppKit
import Foundation
import UniformTypeIdentifiers
import PDFKit

// Keep the original raw values so existing appearance preferences still work.
enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case light, warm, dark
    var id: String { rawValue }
    var iconName: String { self == .dark ? "moon.stars" : "sun.max" }
    var textKey: AppTextKey {
        switch self {
        case .light: return .themeBlue
        case .warm: return .themeWarm
        case .dark: return .themeGraphite
        }
    }
    var preferredColorScheme: ColorScheme { self == .dark ? .dark : .light }
    var palette: WorkspacePalette {
        switch self {
        case .light: return .blue
        case .warm: return .warm
        case .dark: return .graphite
        }
    }
}

struct WorkspacePalette {
    let sidebar: Color
    let results: Color
    let canvas: Color
    let input: Color
    let text: Color
    let secondary: Color
    let divider: Color
    let accent: Color
    let selection: Color
    let button: Color

    static let blue = WorkspacePalette(
        sidebar: Color(hex: 0xEEF2F7), results: Color(hex: 0xF7F9FC), canvas: .white,
        input: .white, text: Color(hex: 0x20242B), secondary: Color(hex: 0x647083),
        divider: Color(hex: 0xDFE5ED), accent: Color(hex: 0x086DD3),
        selection: Color(hex: 0xE1EEFF), button: Color(hex: 0x0874DA))
    static let warm = WorkspacePalette(
        sidebar: Color(hex: 0xEEEDE7), results: Color(hex: 0xF5F3EE), canvas: Color(hex: 0xFAF9F6),
        input: Color(hex: 0xFDFCFA), text: Color(hex: 0x252A28), secondary: Color(hex: 0x6C756E),
        divider: Color(hex: 0xDEDED6), accent: Color(hex: 0x286A5D),
        selection: Color(hex: 0xE0EBE4), button: Color(hex: 0x326F62))
    static let graphite = WorkspacePalette(
        sidebar: Color(hex: 0x191B1F), results: Color(hex: 0x202226), canvas: Color(hex: 0x25272C),
        input: Color(hex: 0x2D3036), text: Color(hex: 0xF1F3F5), secondary: Color(hex: 0xADB4BF),
        divider: Color(hex: 0x3D424B), accent: Color(hex: 0x8EC2FF),
        selection: Color(hex: 0x293F5B), button: Color(hex: 0x1973D5))
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

private struct WorkspaceFrostedMaterial: NSViewRepresentable {
    let behindWindow: Bool
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = behindWindow ? .sidebar : .contentBackground
        view.blendingMode = behindWindow ? .behindWindow : .withinWindow
        view.state = .followsWindowActiveState
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = behindWindow ? .sidebar : .contentBackground
        view.blendingMode = behindWindow ? .behindWindow : .withinWindow
    }
}

private struct WorkspaceGlassSurface: View {
    let tint: Color
    var behindWindow = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        ZStack {
            if reduceTransparency { tint }
            else {
                WorkspaceFrostedMaterial(behindWindow: behindWindow)
                tint.opacity(behindWindow ? 0.72 : 0.82)
                LinearGradient(colors: [.white.opacity(0.14), .clear, .white.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct WorkspaceSelectionSurface: View {
    let palette: WorkspacePalette
    let selected: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(selected ? palette.selection.opacity(0.85) : .clear)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(LinearGradient(colors: [.white.opacity(0.5), palette.accent.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.7)
                }
            }
            .shadow(color: palette.accent.opacity(selected ? 0.045 : 0), radius: 5, y: 2)
    }
}

private enum WorkspaceAppIcon {
    static let image: NSImage = {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"), let icon = NSImage(contentsOf: url) { return icon }
        return NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
    }()
}

enum WorkspaceLayout {
    static let sidebarWidth: CGFloat = 244
    static let workflowTextLeading: CGFloat = 78
    static let titlebarHeight: CGFloat = 76
    static let paneHeaderHeight: CGFloat = 124
    static let paneFooterHeight: CGFloat = 144
}

// Only content and detail participate in the native split; the sidebar is fixed.
private struct WorkspaceColumnSplit<Content: View, Detail: View>: NSViewRepresentable {
    let content: Content
    let detail: Detail
    let palette: WorkspacePalette
    let colorScheme: ColorScheme

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSSplitView {
        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.delegate = context.coordinator
        for host in context.coordinator.hosts {
            host.sizingOptions = []
            split.addArrangedSubview(host)
        }
        updateNSView(split, context: context)
        return split
    }

    func updateNSView(_ split: NSSplitView, context: Context) {
        context.coordinator.hosts[0].rootView = hosted(content)
        context.coordinator.hosts[1].rootView = hosted(detail)
        split.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
    }

    private func hosted<V: View>(_ view: V) -> AnyView {
        AnyView(view.frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.system(size: 16)).foregroundStyle(palette.text)
            .tint(palette.accent).accentColor(palette.accent)
            .environment(\.colorScheme, colorScheme))
    }

    final class Coordinator: NSObject, NSSplitViewDelegate {
        let hosts = (0..<2).map { _ in NSHostingView(rootView: AnyView(EmptyView())) }
        private var initialized = false
        private let minimums: [CGFloat] = [280, 320]

        func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
            let available = splitView.bounds.width - splitView.dividerThickness
            guard available > 0 else { return }
            let hints = initialized ? hosts.map { $0.frame.width } : [400, max(320, available - 400)]
            let extra = max(0, available - minimums.reduce(0, +))
            let weights = zip(hints, minimums).map { max(0, $0 - $1) }
            let total = weights.reduce(0, +)
            let widths = (0..<2).map { minimums[$0] + extra * (total > 0 ? weights[$0] / total : 0.5) }
            var x: CGFloat = 0
            for index in 0..<2 {
                hosts[index].frame = NSRect(x: x, y: 0, width: widths[index], height: splitView.bounds.height)
                x += widths[index] + splitView.dividerThickness
            }
            initialized = true
        }

        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            minimums[0]
        }

        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            splitView.bounds.width - splitView.dividerThickness - minimums[1]
        }

        func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool { false }
    }
}

@MainActor
final class WorkspaceNavigation: ObservableObject {
    @Published var step: Int
    @Published var field: DublinCoreField = .title
    init(step: Int = 1) { self.step = step }

    func resumeFile(_ id: UUID, using viewModel: MainViewModel) {
        guard viewModel.items.contains(where: { $0.id == id }) else { return }
        viewModel.selectItem(id)
        step = viewModel.currentStep
    }
}

struct PDFSelectionDetails {
    let bytes: Int?
    let pages: Int?
    let modified: Date?

    static func read(_ url: URL) -> PDFSelectionDetails {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let pages = FileManager.default.fileExists(atPath: url.path) ? PDFDocument(url: url)?.pageCount : nil
        return PDFSelectionDetails(bytes: values?.fileSize, pages: pages, modified: values?.contentModificationDate)
    }
}

@MainActor
struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    @StateObject private var navigation: WorkspaceNavigation
    @State private var logsExpanded = false
    @State private var showLookupOptions = true
    @State private var showResultSearch = false
    @State private var resultQuery = ""
    @State private var sourceFilter = ""
    @State private var fileDetails: PDFSelectionDetails?

    init() {
        _viewModel = StateObject(wrappedValue: MainViewModel())
        _navigation = StateObject(wrappedValue: WorkspaceNavigation())
    }

    init(viewModel: MainViewModel, initialStep: Int? = nil, navigation: WorkspaceNavigation? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _navigation = StateObject(wrappedValue: navigation ?? WorkspaceNavigation(step: initialStep ?? viewModel.currentStep))
    }

    private var palette: WorkspacePalette { viewModel.appearanceMode.palette }
    private func text(_ key: AppTextKey) -> String { viewModel.text(key) }
    private var candidate: BookMetadataCandidate? {
        guard let item = viewModel.selectedItem else { return nil }
        return item.candidates.first { $0.id == item.selectedCandidateID }
    }
    private var visibleCandidates: [BookMetadataCandidate] {
        (viewModel.selectedItem?.candidates ?? []).filter {
            (sourceFilter.isEmpty || $0.source == sourceFilter) &&
            (resultQuery.isEmpty || "\($0.primaryTitle) \($0.authorsText) \($0.source)".localizedCaseInsensitiveContains(resultQuery))
        }
    }
    private var canWrite: Bool { candidate != nil && !viewModel.selectedDublinCoreFields.isEmpty && !viewModel.isSearching }
    private var sourcesEnabled: Bool {
        viewModel.sourceOptions.useGoogleBooks || viewModel.sourceOptions.useOpenLibrary ||
        viewModel.sourceOptions.useDoubanWebSearch || viewModel.sourceOptions.useLibraryOfCongress
    }
    private var rule: some View { Rectangle().fill(palette.divider).frame(height: 1) }

    var body: some View {
        VStack(spacing: 0) {
            titlebar
            rule
            HStack(spacing: 0) {
                sidebar.frame(width: WorkspaceLayout.sidebarWidth)
                Rectangle().fill(palette.divider).frame(width: 1)
                WorkspaceColumnSplit(content: contentPane, detail: detailPane,
                                     palette: palette, colorScheme: viewModel.preferredColorScheme)
            }.frame(maxHeight: .infinity).background(palette.divider)
            logDrawer
        }
        .background(palette.canvas)
        .ignoresSafeArea(.container, edges: .top)
        .font(.system(size: 16)).foregroundStyle(palette.text)
        .tint(palette.accent).accentColor(palette.accent)
        .preferredColorScheme(viewModel.preferredColorScheme)
        .sheet(isPresented: $viewModel.showWriteConfirmation, onDismiss: { viewModel.cancelWriteConfirmation() }) {
            if let preview = viewModel.pendingWritePreview {
                MetadataWriteConfirmation(preview: preview, language: viewModel.language, palette: palette,
                    onCancel: { viewModel.cancelWriteConfirmation() },
                    onConfirm: {
                        viewModel.showWriteConfirmation = false
                        viewModel.performWriteConfirmed()
                        if viewModel.selectedItem?.stage == .written { navigation.step = 4 }
                    })
                    .preferredColorScheme(viewModel.preferredColorScheme)
            }
        }
        .onAppear { showLookupOptions = candidate == nil }
        .onChange(of: viewModel.selectedItemID) { _ in
            // Changing the object updates its details, not the selected workflow.
            navigation.field = .title
            sourceFilter = ""
            resultQuery = ""
            showLookupOptions = candidate == nil
        }
        .onChange(of: viewModel.isSearching) { searching in
            if !searching && candidate != nil { showLookupOptions = false }
        }
        .task(id: viewModel.selectedItem?.url) {
            fileDetails = viewModel.selectedItem.map { PDFSelectionDetails.read($0.url) }
        }
    }

    private var titlebar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(nsImage: WorkspaceAppIcon.image).resizable().interpolation(.high)
                    .frame(width: 28, height: 28).accessibilityHidden(true)
                Text("PDF Librarian").font(.system(size: 17, weight: .semibold))
            }.frame(width: WorkspaceLayout.sidebarWidth)
            Rectangle().fill(palette.divider).frame(width: 1, height: 20)
            HStack(spacing: 10) {
                Image(systemName: "doc.text").foregroundStyle(palette.secondary)
                Text(viewModel.selectedItem?.url.lastPathComponent ?? text(.workspaceWelcome))
                    .font(.system(size: 13)).lineLimit(1).truncationMode(.middle)
                Spacer(minLength: 12)
            }.padding(.horizontal, 24)
        }
        .padding(.top, 24) // Leave the native window controls their own row.
        .frame(height: WorkspaceLayout.titlebarHeight).background(WorkspaceGlassSurface(tint: palette.sidebar, behindWindow: true))
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    sectionLabel(text(.workflowNavigation))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, WorkspaceLayout.workflowTextLeading - 16).padding(.bottom, 10)
                    ForEach(1...4, id: \.self) { step in stepNavigation(step) }
                    if !viewModel.items.isEmpty {
                        rule.padding(.vertical, 16)
                        HStack(spacing: 6) {
                            sectionLabel(text(.currentBatch))
                            Text("\(viewModel.items.count)").font(.system(size: 12)).foregroundStyle(palette.secondary)
                        }.padding(.bottom, 8)
                        LazyVStack(spacing: 6) {
                            ForEach(viewModel.items) { item in sidebarFileRow(item) }
                        }
                    }
                }.padding(.vertical, 24).padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
            }
            VStack(spacing: 18) {
                rule
                HStack(spacing: 16) {
                    ForEach(AppLanguage.allCases) { language in
                        Button { viewModel.setLanguage(language) } label: {
                            WorkspaceLanguageFlag(language: language)
                                .frame(width: 32, height: 32).clipShape(Circle())
                                .overlay(Circle().stroke(viewModel.language == language ? palette.accent : palette.secondary.opacity(0.4), lineWidth: viewModel.language == language ? 2 : 1))
                                .padding(3)
                                .overlay(Circle().stroke(viewModel.language == language ? palette.accent.opacity(0.3) : .clear, lineWidth: 1))
                        }.buttonStyle(.plain).help(language.nativeName)
                            .accessibilityLabel(language.nativeName)
                            .accessibilityAddTraits(viewModel.language == language ? .isSelected : [])
                    }
                }.frame(maxWidth: .infinity)
                HStack(spacing: 16) {
                    ForEach(AppAppearanceMode.allCases) { mode in
                        Button { viewModel.setAppearanceMode(mode) } label: {
                            Circle().fill(mode == .dark ? Color(hex: 0x25272C) : (mode == .warm ? Color(hex: 0xF6F0E0) : Color(hex: 0xDDEDFE)))
                                .overlay(Circle().stroke(viewModel.appearanceMode == mode ? palette.accent : palette.secondary.opacity(0.4), lineWidth: viewModel.appearanceMode == mode ? 2 : 1))
                                .overlay {
                                    if viewModel.appearanceMode == mode {
                                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(mode == .dark ? Color.white : Color(hex: 0x245A56))
                                    }
                                }.frame(width: 32, height: 32).padding(3)
                        }
                        .buttonStyle(.plain).help(viewModel.appearanceModeLabel(mode))
                        .accessibilityLabel(viewModel.appearanceModeLabel(mode))
                        .accessibilityAddTraits(viewModel.appearanceMode == mode ? .isSelected : [])
                    }
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, 24).padding(.bottom, 24)
        }.background(WorkspaceGlassSurface(tint: palette.sidebar, behindWindow: true))
    }

    private func sidebarFileRow(_ item: PDFWorkItem) -> some View {
        let selected = viewModel.selectedItemID == item.id
        return Button { navigation.resumeFile(item.id, using: viewModel) } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.stage == .failed ? "exclamationmark.circle" : "doc.text")
                    .font(.system(size: 17)).foregroundStyle(item.stage == .failed ? Color.red : palette.accent)
                    .frame(width: 20).padding(.top, 2)
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.url.deletingPathExtension().lastPathComponent)
                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                        .lineLimit(2).truncationMode(.middle).multilineTextAlignment(.leading)
                    Text(item.stage.displayName).font(.system(size: 11)).foregroundStyle(palette.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.padding(10).frame(maxWidth: .infinity)
                .background(WorkspaceSelectionSurface(palette: palette, selected: selected))
                .contentShape(Rectangle())
        }.buttonStyle(.plain).help(item.url.path)
            .accessibilityLabel("\(item.url.lastPathComponent), \(item.stage.displayName)")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func sectionLabel(_ label: String) -> some View {
        Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(palette.secondary)
    }

    private func isComplete(_ step: Int) -> Bool {
        guard let item = viewModel.selectedItem else { return false }
        switch step {
        case 1: return true
        case 2: return !item.candidates.isEmpty
        case 3: return [.written, .renamed, .renameSkipped].contains(item.stage) || viewModel.hasPendingRename(for: item.id)
        default: return [.renamed, .renameSkipped].contains(item.stage)
        }
    }

    private func navigate(_ step: Int) {
        navigation.step = step
        if step == 4, !viewModel.saveItems.contains(where: { $0.id == viewModel.selectedItemID }), let first = viewModel.saveItems.first {
            selectFile(first.id)
        }
    }

    private func selectFile(_ id: UUID) { viewModel.selectItem(id) }

    private func stepNavigation(_ step: Int) -> some View {
        let active = navigation.step == step
        let complete = isComplete(step)
        let keys: [AppTextKey] = [.navigationFiles, .navigationSearch, .navigationEdit, .navigationSave]
        let icons = ["folder", "magnifyingglass", "pencil", "square.and.arrow.down"]
        return Button { navigate(step) } label: {
            HStack(spacing: 14) {
                Image(systemName: complete && !active ? "checkmark.circle.fill" : icons[step - 1])
                    .font(.system(size: 20, weight: .medium)).frame(width: 28)
                    .foregroundStyle(active || complete ? palette.accent : palette.secondary)
                VStack(alignment: .leading, spacing: 5) {
                    Text(text(keys[step - 1])).font(.system(size: 16, weight: active ? .semibold : .medium))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(text(complete ? .completed : (active ? .currentStepLabel : .pending)))
                        .font(.system(size: 12)).foregroundStyle(active ? palette.accent : palette.secondary)
                }
                .frame(maxWidth: 130, alignment: .leading)
            }
            .foregroundStyle(active ? palette.accent : palette.text)
            .padding(.leading, 20).padding(.trailing, 10).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WorkspaceSelectionSurface(palette: palette, selected: active))
            .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel("\(step). \(text(keys[step - 1]))")
            .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var contentHeading: (String, String) {
        switch navigation.step {
        case 1: return (text(.navigationFiles), text(.importSubtitle))
        case 2: return (text(.navigationSearch), text(.lookupColumnHint))
        case 3: return (text(.editMetadata), text(.fieldColumnHint))
        default: return (text(.navigationSave), text(.saveColumnHint))
        }
    }

    private var detailHeading: (String, String) {
        switch navigation.step {
        case 1: return (text(.fileDetailsTitle), text(.fileDetailsSubtitle))
        case 2: return (text(.candidateDetailsTitle), text(.candidateDetailsSubtitle))
        case 3: return candidate == nil ? (text(.editMetadata), text(.fieldColumnHint)) : ("\(navigation.field.emoji) \(text(navigation.field.labelKey))", navigation.field.rawValue)
        default: return (text(.navigationSave), text(.saveSubtitle))
        }
    }

    private func paneHeader(_ value: (String, String), color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(value.0).font(.system(size: 25, weight: .semibold)).foregroundStyle(color ?? palette.text).lineLimit(1)
                .frame(height: 32, alignment: .leading)
            Text(value.1).font(.system(size: 13)).foregroundStyle(palette.secondary)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                .frame(height: 36, alignment: .topLeading)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).frame(height: WorkspaceLayout.paneHeaderHeight, alignment: .center)
    }

    private var contentPane: some View {
        VStack(spacing: 0) {
            paneHeader(contentHeading)
            rule
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch navigation.step {
                    case 1: filesContent
                    case 2: lookupContent
                    case 3: fieldsContent
                    default: saveFilesContent
                    }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            }
            rule
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(text(.currentFile))
                Text(viewModel.selectedItem?.url.lastPathComponent ?? text(.noPDFLoaded))
                    .font(.system(size: 12)).foregroundStyle(palette.secondary)
                    .lineLimit(2).truncationMode(.middle)
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).frame(height: WorkspaceLayout.paneFooterHeight)
        }.background(WorkspaceGlassSurface(tint: palette.results))
    }

    private var filesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                if viewModel.pickSource() { viewModel.loadPDFsFromSource() }
            } label: { Label(text(.chooseFileOrFolder), systemImage: "folder.badge.plus") }
                .buttonStyle(WorkspaceButtonStyle(palette: palette)).disabled(viewModel.isSearching)
            if !viewModel.sourcePath.isEmpty {
                Text(viewModel.sourcePath).font(.system(size: 11)).foregroundStyle(palette.secondary)
                    .lineLimit(3).truncationMode(.middle).textSelection(.enabled)
            }
            rule
            HStack { sectionLabel(text(.currentBatch)); Text("\(viewModel.items.count)").monospacedDigit().foregroundStyle(palette.secondary) }
            if viewModel.items.isEmpty {
                WorkspaceEmptyState(icon: "folder", title: text(.batchEmpty), detail: text(.selectFileForDetails), palette: palette)
            }
            if !viewModel.items.isEmpty {
                Text(text(.fileQueueHint)).font(.system(size: 13)).foregroundStyle(palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var fileContextPicker: some View {
        Picker(text(.currentFile), selection: Binding(get: { viewModel.selectedItemID }, set: { if let id = $0 { selectFile(id) } })) {
            if viewModel.selectedItemID == nil { Text(text(.noPDFLoaded)).tag(Optional<UUID>.none) }
            ForEach(viewModel.items) { item in Text(item.url.lastPathComponent).tag(Optional(item.id)) }
        }.pickerStyle(.menu).font(.system(size: 12)).disabled(viewModel.items.isEmpty)
    }

    private var lookupContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            fileContextPicker
            if let item = viewModel.selectedItem {
                DisclosureGroup(isExpanded: $showLookupOptions) {
                    VStack(alignment: .leading, spacing: 16) {
                        WorkspaceInput(title: text(.hintFileNameLabel), placeholder: text(.hintFileNamePlaceholder),
                            value: Binding(get: { viewModel.searchHintFileName(for: item.id) }, set: { viewModel.updateSearchHintFileName($0, for: item.id) }), palette: palette)
                        WorkspaceInput(title: text(.hintExtractedTitleLabel), placeholder: text(.hintExtractedTitlePlaceholder),
                            value: Binding(get: { viewModel.searchHintExtractedTitle(for: item.id) }, set: { viewModel.updateSearchHintExtractedTitle($0, for: item.id) }), palette: palette)
                        Toggle("Google Books", isOn: $viewModel.sourceOptions.useGoogleBooks)
                        Toggle("Open Library", isOn: $viewModel.sourceOptions.useOpenLibrary)
                        Toggle(text(.sourceDouban), isOn: $viewModel.sourceOptions.useDoubanWebSearch)
                        Toggle("Library of Congress", isOn: $viewModel.sourceOptions.useLibraryOfCongress)
                    }.font(.system(size: 13)).toggleStyle(WorkspaceCheckboxStyle(palette: palette)).padding(.top, 14)
                } label: { Text(text(.lookupOptions)).font(.system(size: 13, weight: .medium)) }
                Button { viewModel.searchMetadataForSelectedItem() } label: {
                    Label(text(viewModel.isSearching ? .buttonSearching : .startLookup), systemImage: "magnifyingglass")
                }.buttonStyle(WorkspaceButtonStyle(palette: palette)).disabled(viewModel.isSearching || !sourcesEnabled)
                rule
                HStack(spacing: 8) {
                    Text(text(.searchResults)).font(.system(size: 16, weight: .semibold))
                    Text("\(item.candidates.count)").font(.system(size: 13)).foregroundStyle(palette.secondary)
                    Spacer(minLength: 0)
                    Menu {
                        Button(text(.allSources)) { sourceFilter = "" }
                        ForEach(Array(Set(item.candidates.map(\.source))).sorted(), id: \.self) { source in Button(source) { sourceFilter = source } }
                    } label: { Text(sourceFilter.isEmpty ? text(.allSources) : sourceFilter).font(.system(size: 11)).lineLimit(1) }
                    .menuStyle(.borderlessButton).frame(maxWidth: 110)
                    Button { showResultSearch.toggle() } label: { Image(systemName: "line.3.horizontal.decrease") }
                        .buttonStyle(.plain).accessibilityLabel(text(.filterResults)).help(text(.filterResults))
                }
                if showResultSearch {
                    TextField(text(.filterResults), text: $resultQuery).textFieldStyle(.roundedBorder)
                }
                if viewModel.isSearching { ProgressView(text(.buttonSearching)).controlSize(.small).font(.system(size: 12)) }
                if visibleCandidates.isEmpty && !viewModel.isSearching {
                    WorkspaceEmptyState(icon: "magnifyingglass", title: text(.noCandidates), detail: text(.selectCandidateForDetails), palette: palette)
                }
                LazyVStack(spacing: 0) {
                    ForEach(visibleCandidates) { result in candidateRow(result); rule }
                }
            } else {
                WorkspaceEmptyState(icon: "doc.badge.plus", title: text(.loadAndSelectFirst), detail: text(.resultsEmptyDetail), palette: palette)
            }
        }
    }

    private var fieldsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            fileContextPicker
            if candidate != nil {
                HStack {
                    Text("\(text(.selectedFieldsShort)) \(viewModel.selectedDublinCoreFields.count)/12").font(.system(size: 12)).foregroundStyle(palette.secondary)
                    Spacer(minLength: 0)
                    Toggle(text(.selectAllFields), isOn: Binding(
                        get: { viewModel.selectedDublinCoreFields.count == DublinCoreField.allCases.count },
                        set: { viewModel.selectedDublinCoreFields = $0 ? Set(DublinCoreField.allCases) : [] }))
                        .toggleStyle(WorkspaceCheckboxStyle(palette: palette)).font(.system(size: 12))
                }
                fieldGroup(.basicFields, fields: [.title, .creator, .publisher, .date, .language])
                fieldGroup(.documentFields, fields: [.type, .format, .identifier, .subject])
                fieldGroup(.additionalFields, fields: [.source, .relation, .description])
            } else {
                WorkspaceEmptyState(icon: "text.badge.checkmark", title: text(.noSelectedCandidate), detail: text(.selectCandidateForDetails), palette: palette)
            }
        }
    }

    private func fieldGroup(_ title: AppTextKey, fields: [DublinCoreField]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionLabel(text(title)).padding(.horizontal, 10)
            ForEach(fields, id: \.self) { field in
                HStack(spacing: 10) {
                    Toggle("", isOn: Binding(get: { viewModel.selectedDublinCoreFields.contains(field) }, set: { viewModel.setDublinCoreField(field, enabled: $0) }))
                        .toggleStyle(WorkspaceCheckboxStyle(palette: palette)).labelsHidden()
                        .accessibilityLabel("\(text(.includeField)) \(text(field.labelKey))")
                    Button { navigation.field = field } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(field.emoji) \(text(field.labelKey))").font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(field.color(for: viewModel.preferredColorScheme) ?? palette.text)
                                Text(field.rawValue).font(.system(size: 11)).foregroundStyle(palette.secondary)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(palette.secondary)
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityAddTraits(navigation.field == field ? .isSelected : [])
                }.padding(10).background(WorkspaceSelectionSurface(palette: palette, selected: navigation.field == field))
            }
        }
    }

    private var saveFilesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.saveItems.isEmpty {
                WorkspaceEmptyState(icon: "square.and.arrow.down", title: text(.noSaveItems), detail: text(.writeFirst), palette: palette)
            } else {
                let pending = viewModel.saveItems.filter { ![.renamed, .renameSkipped].contains($0.stage) }
                let completed = viewModel.saveItems.filter { [.renamed, .renameSkipped].contains($0.stage) }
                if !pending.isEmpty {
                    sectionLabel(text(.pending))
                    ForEach(pending) { item in fileRow(item) }
                }
                if !completed.isEmpty {
                    rule
                    sectionLabel(text(.completed))
                    ForEach(completed) { item in fileRow(item) }
                }
            }
        }
    }

    private var detailPane: some View {
        VStack(spacing: 0) {
            paneHeader(detailHeading, color: navigation.step == 3 ? navigation.field.color(for: viewModel.preferredColorScheme) : nil)
            rule
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch navigation.step {
                    case 1: filePreparation
                    case 2: candidateDetails
                    case 3: fieldDetails
                    default: saveContent
                    }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            }
            rule
            actionFooter
        }.background(WorkspaceGlassSurface(tint: palette.canvas))
    }

    private var filePreparation: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let item = viewModel.selectedItem {
                Label(item.url.lastPathComponent, systemImage: "doc.richtext").font(.system(size: 18, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                infoRow(text(.fileLocation), value: item.url.deletingLastPathComponent().path)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), alignment: .leading)], alignment: .leading, spacing: 20) {
                    if let bytes = fileDetails?.bytes { infoRow(text(.fileSize), value: ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)) }
                    if let pages = fileDetails?.pages { infoRow(text(.pageCount), value: "\(pages)") }
                    if let modified = fileDetails?.modified {
                        infoRow(text(.modifiedDate), value: modified.formatted(.dateTime.year().month().day().locale(Locale(identifier: viewModel.language.localeIdentifier))))
                    }
                }
                rule
                sectionLabel(text(.lookupPreparation))
                infoRow(text(.hintFileNameLabel), value: item.hint.fileNameTitle)
                infoRow(text(.hintExtractedTitleLabel), value: item.hint.extractedTitle)
                if let isbn = item.hint.isbn { infoRow("ISBN", value: isbn) }
                if let doi = item.hint.doi { infoRow("DOI", value: doi) }
                if !item.hint.snippet.isEmpty {
                    DisclosureGroup(text(.extractedSnippet)) {
                        Text(item.hint.snippet).font(.system(size: 13)).textSelection(.enabled).padding(.top, 10)
                    }
                }
            } else {
                WorkspaceEmptyState(icon: "doc.text.magnifyingglass", title: text(.selectFileForDetails), detail: text(.batchEmpty), palette: palette)
            }
        }
    }

    private var candidateDetails: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let candidate {
                Text(candidate.primaryTitle).font(.system(size: 22, weight: .semibold)).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                infoRow(text(.fieldAuthor), value: candidate.authorsText)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), alignment: .leading)], alignment: .leading, spacing: 24) {
                    infoRow(text(.fieldPublisher), value: candidate.publisher)
                    infoRow(text(.fieldYear), value: candidate.publishedYear)
                    infoRow(text(.fieldLanguage), value: candidate.language)
                    infoRow(text(.fieldType), value: candidate.kind.displayName)
                }
                if !candidate.isbn.isEmpty { infoRow("ISBN", value: candidate.isbn) }
                if !candidate.doi.isEmpty { infoRow("DOI", value: candidate.doi) }
                rule
                infoRow(text(.currentSource), value: "\(candidate.source) · \(text(.matchConfidence)) \(candidate.confidence)%")
                if !candidate.validatedBy.isEmpty { infoRow(text(.validationSources), value: candidate.validatedBy.joined(separator: " · ")) }
                if let url = sourceURL(candidate.sourceURL) {
                    Link(destination: url) { Label(text(.openSource), systemImage: "arrow.up.right.square") }.font(.system(size: 13))
                }
            } else {
                WorkspaceEmptyState(icon: "book", title: text(.selectCandidateForDetails), detail: text(.lookupColumnHint), palette: palette)
            }
        }
    }

    private func sourceURL(_ value: String) -> URL? {
        guard let url = URL(string: value), ["http", "https"].contains(url.scheme ?? "") else { return nil }
        return url
    }

    private func infoRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(palette.secondary)
            Text(value.isEmpty ? "—" : value).font(.system(size: 15)).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fieldDetails: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let candidate, let item = viewModel.selectedItem {
                Text(item.url.lastPathComponent).font(.system(size: 12)).foregroundStyle(palette.secondary).lineLimit(2)
                Text(text(.editableValue)).font(.system(size: 14, weight: .medium))
                TextEditor(text: Binding(get: { viewModel.editableDublinCoreValues[navigation.field] ?? "" }, set: { viewModel.updateEditableDublinCoreValue($0, for: navigation.field) }))
                    .font(.system(size: 16)).scrollContentBackground(.hidden)
                    .padding(10).frame(minHeight: 160, maxHeight: 220)
                    .background(palette.input.opacity(0.75), in: RoundedRectangle(cornerRadius: 7))
                    .shadow(color: palette.text.opacity(0.035), radius: 8, y: 3)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(palette.divider, lineWidth: 1))
                    .accessibilityLabel("\(text(.editableValue)) \(text(navigation.field.labelKey))")
                    .id("\(item.id)-\(candidate.id)-\(navigation.field.rawValue)")
                Toggle(text(.includeField), isOn: Binding(get: { viewModel.selectedDublinCoreFields.contains(navigation.field) }, set: { viewModel.setDublinCoreField(navigation.field, enabled: $0) }))
                    .toggleStyle(WorkspaceCheckboxStyle(palette: palette)).font(.system(size: 13))
                rule
                infoRow(text(.originalSourceValue), value: viewModel.dublinCoreValueMap(for: candidate, fileURL: item.url)[navigation.field] ?? "")
                infoRow(text(.currentSource), value: candidate.source)
                Text(text(.writeAllSelectedHint)).font(.system(size: 12)).foregroundStyle(palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                    WorkspaceEmptyState(icon: "text.badge.checkmark", title: text(.noSelectedCandidate), detail: text(.selectCandidateForDetails), palette: palette)
            }
        }
    }

    private var actionFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            if navigation.step == 3 {
                Text("\(text(.selectedFieldsShort)) \(viewModel.selectedDublinCoreFields.count)/12 · \(text(.checkedFieldsOnly))")
                    .font(.system(size: 11)).foregroundStyle(palette.secondary).fixedSize(horizontal: false, vertical: true)
            }
            ViewThatFits(in: .horizontal) {
                HStack { secondaryAction; Spacer(minLength: 12); primaryAction }
                VStack(alignment: .trailing, spacing: 12) { primaryAction; secondaryAction }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }.padding(20).frame(height: WorkspaceLayout.paneFooterHeight).background(WorkspaceGlassSurface(tint: palette.canvas))
    }

    @ViewBuilder private var secondaryAction: some View {
        if navigation.step == 4, viewModel.renamePrompt?.itemID == viewModel.selectedItemID, viewModel.renamePrompt != nil {
            Button(text(.buttonSkipRename)) { viewModel.skipRenameForPrompt() }.buttonStyle(.plain).foregroundStyle(palette.secondary)
        }
    }

    @ViewBuilder private var primaryAction: some View {
        switch navigation.step {
        case 1:
            Button { navigate(2) } label: { Label(text(.lookupThisFile), systemImage: "arrow.right") }
                .buttonStyle(WorkspaceButtonStyle(palette: palette)).disabled(viewModel.selectedItem == nil)
        case 2:
            if viewModel.selectedItem == nil {
                Button(text(.navigationFiles)) { navigate(1) }.buttonStyle(WorkspaceButtonStyle(palette: palette, primary: false))
            } else {
                Button { navigate(3) } label: { Label(text(.useCandidateAndEdit), systemImage: "arrow.right") }
                    .buttonStyle(WorkspaceButtonStyle(palette: palette)).disabled(candidate == nil || viewModel.isSearching)
            }
        case 3:
            if candidate == nil {
                Button(text(.backToSearch)) { navigate(2) }.buttonStyle(WorkspaceButtonStyle(palette: palette, primary: false))
            } else {
                Button { viewModel.askWriteConfirmationForSelectedItem() } label: { Label(text(.reviewAndWrite), systemImage: "arrow.right") }
                    .buttonStyle(WorkspaceButtonStyle(palette: palette)).keyboardShortcut(.return, modifiers: .command).disabled(!canWrite)
            }
        default:
            if viewModel.renamePrompt?.itemID == viewModel.selectedItemID, viewModel.renamePrompt != nil {
                Button { viewModel.confirmRenameForPrompt() } label: { Label(text(.chooseSaveLocation), systemImage: "square.and.arrow.down") }
                    .buttonStyle(WorkspaceButtonStyle(palette: palette))
            } else if let item = viewModel.selectedItem, [.renamed, .renameSkipped].contains(item.stage) {
                Button(text(.navigationFiles)) { navigate(1) }.buttonStyle(WorkspaceButtonStyle(palette: palette, primary: false))
            } else {
                Button(text(.backToEditor)) { navigate(3) }.buttonStyle(WorkspaceButtonStyle(palette: palette, primary: false))
                    .disabled(candidate == nil)
            }
        }
    }

    private func fileRow(_ item: PDFWorkItem) -> some View {
        let selected = viewModel.selectedItemID == item.id
        return Button { selectFile(item.id) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.richtext").font(.system(size: 22)).foregroundStyle(selected ? palette.accent : palette.secondary)
                    .frame(width: 26).padding(.top, 3)
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.url.deletingPathExtension().lastPathComponent).lineLimit(1).truncationMode(.tail)
                    Label(item.stage.displayName, systemImage: item.stage == .failed ? "exclamationmark.circle" :
                          ([.renamed, .renameSkipped].contains(item.stage) ? "checkmark.circle.fill" : "circle.fill"))
                        .font(.system(size: 11)).foregroundStyle(item.stage == .failed ? Color.red : palette.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(WorkspaceSelectionSurface(palette: palette, selected: selected))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).help(item.url.path)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func candidateRow(_ result: BookMetadataCandidate) -> some View {
        let selected = candidate?.id == result.id
        return Button {
            guard let item = viewModel.selectedItem else { return }
            viewModel.chooseCandidate(result.id, for: item.id)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "book").font(.system(size: 26, weight: .light)).foregroundStyle(palette.secondary)
                    .frame(width: 30).padding(.top, 3)
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.primaryTitle).font(.system(size: 16, weight: .medium)).lineLimit(3)
                    Text(result.authors.count > 1 ? "\(result.authors[0]) et al." : result.authorsText).font(.system(size: 14)).foregroundStyle(palette.secondary).lineLimit(1).help(result.authorsText)
                    Text([result.publisher, result.publishedYear].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.system(size: 14)).foregroundStyle(palette.secondary)
                    HStack(spacing: 8) {
                        Text(result.source).font(.system(size: 12)).lineLimit(1)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(palette.divider, lineWidth: 1))
                        Text("\(result.confidence)%").font(.system(size: 13, weight: .medium)).monospacedDigit()
                        Spacer(minLength: 0)
                        if selected {
                            ViewThatFits {
                                Label(text(.selectedResult), systemImage: "checkmark").font(.system(size: 11))
                                Image(systemName: "checkmark.circle.fill")
                            }.foregroundStyle(palette.accent).help(text(.selectedResult))
                        }
                    }.padding(.top, 3)
                    if !result.validatedBy.isEmpty {
                        Text(result.validatedBy.joined(separator: " · ")).font(.system(size: 10))
                            .foregroundStyle(palette.secondary).lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(WorkspaceSelectionSurface(palette: palette, selected: selected))
            .overlay(alignment: .leading) {
                if selected { RoundedRectangle(cornerRadius: 2).fill(palette.accent).frame(width: 4).padding(.vertical, 4) }
            }
            .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var saveContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let prompt = viewModel.renamePrompt, prompt.itemID == viewModel.selectedItemID {
                Label(text(.metadataWritten), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(palette.accent).font(.system(size: 14, weight: .medium))
                WorkspaceInput(title: text(.renameFileNameLabel), placeholder: text(.renameFileNamePlaceholder),
                    value: Binding(get: { viewModel.renamePromptFileName }, set: { viewModel.updateRenamePromptFileName($0) }), palette: palette)
                Text(text(.fileNameColorPreview)).font(.system(size: 13, weight: .medium))
                RenameFileNamePreview(fileName: prompt.editableFileName, palette: palette, language: viewModel.language)
                Text(text(.renameRuleNote)).font(.system(size: 12)).foregroundStyle(palette.secondary)
                rule
                Text(text(.suggestedFileNameLabel)).font(.system(size: 12)).foregroundStyle(palette.secondary)
                RenameFileNamePreview(fileName: prompt.suggestedFileName, palette: palette, language: viewModel.language, showsLegend: false)
            } else if let item = viewModel.selectedItem, [.renamed, .renameSkipped].contains(item.stage) {
                WorkspaceEmptyState(icon: "checkmark.circle", title: text(.fileComplete), detail: item.url.lastPathComponent, palette: palette)
                    .padding(.top, 50)
            } else {
                WorkspaceEmptyState(icon: "square.and.arrow.down", title: text(.writeFirst),
                    detail: text(.saveSubtitle), palette: palette).padding(.top, 60)
            }
        }
    }

    private var logDrawer: some View {
        VStack(spacing: 0) {
            rule
            if logsExpanded {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            if viewModel.logs.isEmpty { Text(text(.noLogs)).foregroundStyle(palette.secondary) }
                            ForEach(Array(viewModel.logs.enumerated()), id: \.offset) { index, line in
                                Text(line).textSelection(.enabled).id(index)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }.font(.system(size: 11, design: .monospaced)).padding(18)
                    }.frame(height: 160)
                        .onAppear { if let last = viewModel.logs.indices.last { proxy.scrollTo(last, anchor: .bottom) } }
                        .onChange(of: viewModel.logs.count) { _ in
                            if let last = viewModel.logs.indices.last { proxy.scrollTo(last, anchor: .bottom) }
                        }
                }
                rule
            }
            Button { withAnimation(.easeInOut(duration: 0.18)) { logsExpanded.toggle() } } label: {
                HStack(spacing: 10) {
                    if viewModel.isSearching { ProgressView().controlSize(.small) }
                    else {
                        Image(systemName: (viewModel.statusIsError || viewModel.selectedItem?.stage == .failed) ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle((viewModel.statusIsError || viewModel.selectedItem?.stage == .failed) ? Color.red : Color.green)
                    }
                    Text(viewModel.status).font(.system(size: 12)).lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 8)
                    Text(text(.executionLog)).font(.system(size: 12)).foregroundStyle(palette.secondary)
                    Image(systemName: logsExpanded ? "chevron.down" : "chevron.up").font(.system(size: 11)).foregroundStyle(palette.secondary)
                }.padding(.horizontal, 22).frame(height: 44).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel(text(.executionLog))
        }.background(WorkspaceGlassSurface(tint: palette.sidebar, behindWindow: true))
    }
}

struct MetadataWritePreviewRow: Identifiable {
    let field: DublinCoreField
    let originalValue: String
    let proposedValue: String
    let isSelectedForWrite: Bool
    init(field: DublinCoreField, originalValue: String, proposedValue: String, isSelectedForWrite: Bool = true) {
        self.field = field
        self.originalValue = originalValue
        self.proposedValue = proposedValue
        self.isSelectedForWrite = isSelectedForWrite
    }
    var id: DublinCoreField { field }
    var isModified: Bool { originalValue != proposedValue }
    var isRemoval: Bool { !originalValue.isEmpty && proposedValue.isEmpty }
}

struct MetadataWritePreview {
    let fileName: String
    let source: String
    let rows: [MetadataWritePreviewRow]
    var modifiedCount: Int { rows.filter(\.isModified).count }
    var selectedCount: Int { rows.filter(\.isSelectedForWrite).count }
}

struct MetadataWriteConfirmation: View {
    let preview: MetadataWritePreview
    let language: AppLanguage
    let palette: WorkspacePalette
    let onCancel: () -> Void
    let onConfirm: () -> Void
    private func text(_ key: AppTextKey) -> String { AppLocalization.text(key, language: language) }
    @Environment(\.colorScheme) private var colorScheme
    private let valueColumnWidth: CGFloat = 300
    private var rule: some View { Rectangle().fill(palette.divider).frame(height: 1) }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                Label(text(.alertWriteTitle), systemImage: "text.badge.checkmark")
                    .font(.system(size: 24, weight: .semibold))
                Label(preview.fileName, systemImage: "doc.text")
                    .font(.system(size: 13)).foregroundStyle(palette.secondary).lineLimit(1).truncationMode(.middle)
                    .help(preview.fileName)
                Text("\(text(.currentSource)) · \(preview.source)")
                    .font(.system(size: 12)).foregroundStyle(palette.secondary)
                HStack(spacing: 20) {
                    Text("\(text(.selectedFieldsShort)) \(preview.selectedCount)/12")
                    Label("\(text(.modifiedFields)) \(preview.modifiedCount)", systemImage: "pencil.circle.fill")
                        .foregroundStyle(palette.accent)
                }.font(.system(size: 12, weight: .medium))
            }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
            rule
            HStack(spacing: 20) {
                Text(text(.metadataField)).frame(width: 132, alignment: .leading)
                Text(text(.currentFileMetadata)).frame(width: valueColumnWidth, alignment: .leading)
                Text(text(.editableValue)).frame(width: valueColumnWidth, alignment: .leading)
            }.font(.system(size: 12, weight: .semibold)).foregroundStyle(palette.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 38).padding(.vertical, 14)
            rule
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(preview.rows) { row in
                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(row.field.emoji) \(text(row.field.labelKey))").font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(row.field.color(for: colorScheme) ?? palette.text)
                                Text(row.field.rawValue).font(.system(size: 10)).foregroundStyle(palette.secondary)
                            }.frame(width: 132, alignment: .leading)
                            value(row.originalValue, modified: false).frame(width: valueColumnWidth, alignment: .leading)
                            VStack(alignment: .leading, spacing: 7) {
                                value(row.isRemoval ? text(.clearedValue) : row.proposedValue, modified: row.isModified)
                                if row.isModified {
                                    Label(text(row.isRemoval ? .clearedValue : .modifiedValue), systemImage: row.isRemoval ? "minus.circle" : "pencil")
                                        .font(.system(size: 10, weight: .semibold)).foregroundStyle(palette.accent)
                                }
                            }.frame(width: valueColumnWidth, alignment: .leading)
                        }.padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(row.isModified ? palette.selection.opacity(0.65) : palette.input.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .leading) {
                                if row.isModified { RoundedRectangle(cornerRadius: 2).fill(palette.accent).frame(width: 3).padding(.vertical, 10) }
                            }
                    }
                }.padding(.horizontal, 24).padding(.vertical, 16)
            }
            rule
            VStack(alignment: .leading, spacing: 18) {
                Text(text(.writeHighlightHint)).font(.system(size: 12)).foregroundStyle(palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Button(text(.buttonCancel), action: onCancel)
                        .buttonStyle(WorkspaceButtonStyle(palette: palette, primary: false)).keyboardShortcut(.cancelAction)
                    Button(text(.buttonConfirmWrite), action: onConfirm)
                        .buttonStyle(WorkspaceButtonStyle(palette: palette)).keyboardShortcut(.defaultAction)
                        .disabled(preview.rows.isEmpty)
                }
            }.padding(24)
        }.frame(width: 880, height: 680)
            .foregroundStyle(palette.text)
            .background(WorkspaceGlassSurface(tint: palette.canvas))
    }

    private func value(_ value: String, modified: Bool) -> some View {
        Text(value.isEmpty ? "—" : value).font(.system(size: 13, weight: modified ? .medium : .regular))
            .foregroundStyle(modified ? palette.accent : palette.text)
            .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Retain every panel-granted root for the loaded batch, including parent folders.
private final class PDFSourceAccess {
    let urls: [URL]
    private let scopedURLs: [URL]
    init(urls: [URL]) {
        self.urls = urls
        scopedURLs = urls.filter { $0.startAccessingSecurityScopedResource() }
    }
    deinit { scopedURLs.forEach { $0.stopAccessingSecurityScopedResource() } }
}

private struct WorkspaceLanguageFlag: View {
    let language: AppLanguage
    var body: some View {
        Canvas { context, size in
            let scale = size.width / 32
            context.scaleBy(x: scale, y: scale)
            let bounds = CGRect(x: 0, y: 0, width: 32, height: 32)
            if language == .simplifiedChinese {
                context.fill(Path(bounds), with: .color(Color(hex: 0xDE2910)))
                context.fill(star(center: CGPoint(x: 10, y: 11), radius: 5), with: .color(Color(hex: 0xFFDE00)))
                for point in [CGPoint(x: 16, y: 5.5), CGPoint(x: 20, y: 9.5), CGPoint(x: 20, y: 15), CGPoint(x: 16, y: 19)] {
                    let angle = atan2(11 - point.y, 10 - point.x) + .pi / 2
                    context.fill(star(center: point, radius: 1.8, rotation: angle), with: .color(Color(hex: 0xFFDE00)))
                }
            } else {
                context.fill(Path(bounds), with: .color(.white))
                for stripe in stride(from: 0, to: 13, by: 2) {
                    context.fill(Path(CGRect(x: 0, y: CGFloat(stripe) * 32 / 13, width: 32, height: 32 / 13)), with: .color(Color(hex: 0xB22234)))
                }
                context.fill(Path(CGRect(x: 0, y: 0, width: 18, height: 32 * 7 / 13)), with: .color(Color(hex: 0x3C3B6E)))
                for row in 0..<9 {
                    let count = row.isMultiple(of: 2) ? 6 : 5
                    for column in 0..<count {
                        let x = (CGFloat(column) + (count == 6 ? 0.5 : 1)) * 3
                        context.fill(star(center: CGPoint(x: x, y: 1.1 + CGFloat(row) * 1.8), radius: 0.8), with: .color(.white))
                    }
                }
            }
        }.accessibilityHidden(true)
    }

    private func star(center: CGPoint, radius: CGFloat, rotation: CGFloat = 0) -> Path {
        Path { path in
            for point in 0..<10 {
                let angle = CGFloat(point) * .pi / 5 - .pi / 2 + rotation
                let r = point.isMultiple(of: 2) ? radius : radius * 0.382
                let location = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                if point == 0 { path.move(to: location) } else { path.addLine(to: location) }
            }
            path.closeSubpath()
        }
    }
}

private struct WorkspaceCheckboxStyle: ToggleStyle {
    let palette: WorkspacePalette
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(configuration.isOn ? palette.accent : palette.secondary)
                configuration.label
            }.contentShape(Rectangle())
        }
        .buttonStyle(.plain).opacity(enabled ? 1 : 0.45)
        .accessibilityRepresentation {
            Toggle(isOn: Binding(get: { configuration.isOn }, set: { configuration.isOn = $0 })) {
                configuration.label
            }.toggleStyle(.checkbox)
        }
    }
}

private struct WorkspaceEmptyState: View {
    let icon: String
    let title: String
    let detail: String
    let palette: WorkspacePalette
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 38, weight: .light)).foregroundStyle(palette.secondary)
            Text(title).font(.system(size: 15, weight: .medium)).multilineTextAlignment(.center)
            Text(detail).font(.system(size: 12)).foregroundStyle(palette.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 30)
    }
}

private struct WorkspaceInput: View {
    let title: String
    let placeholder: String
    @Binding var value: String
    let palette: WorkspacePalette
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.system(size: 13, weight: .medium))
            TextField(placeholder, text: $value, axis: .vertical).lineLimit(1...4).textFieldStyle(.plain)
                .padding(12).background(palette.input, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(palette.divider, lineWidth: 1))
                .accessibilityLabel(title)
        }
    }
}

private struct WorkspaceButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    let palette: WorkspacePalette
    var primary = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 18).padding(.vertical, 11)
            .foregroundStyle(primary ? Color.white : palette.text)
            .background {
                RoundedRectangle(cornerRadius: 9).fill(primary ? palette.button : palette.results.opacity(0.8))
                    .overlay(RoundedRectangle(cornerRadius: 9).fill(LinearGradient(colors: [.white.opacity(primary ? 0.16 : 0.25), .clear], startPoint: .top, endPoint: .bottom)))
            }
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(primary ? Color.white.opacity(0.22) : palette.divider, lineWidth: 0.8))
            .shadow(color: (primary ? palette.button : palette.text).opacity(primary ? 0.14 : 0.04), radius: 6, y: 3)
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

private extension DublinCoreField {
    var labelKey: AppTextKey {
        switch self {
        case .title: return .fieldTitle
        case .creator: return .fieldAuthor
        case .publisher: return .fieldPublisher
        case .date: return .fieldYear
        case .language: return .fieldLanguage
        case .type: return .fieldType
        case .format: return .fieldFormat
        case .identifier: return .fieldIdentifier
        case .subject: return .fieldSubject
        case .source: return .fieldSource
        case .relation: return .fieldRelation
        case .description: return .fieldDescription
        }
    }
}

enum DublinCoreField: String, CaseIterable, Hashable {
    case title = "dc:title"
    case creator = "dc:creator"
    case publisher = "dc:publisher"
    case date = "dc:date"
    case language = "dc:language"
    case type = "dc:type"
    case format = "dc:format"
    case identifier = "dc:identifier"
    case subject = "dc:subject"
    case source = "dc:source"
    case relation = "dc:relation"
    case description = "dc:description"

    static var defaultSelected: [DublinCoreField] {
        [
            .title,
            .creator,
            .publisher,
            .date,
            .language,
            .type,
            .format,
            .identifier,
            .subject
        ]
    }
}

extension DublinCoreField {
    static let basicFields: [DublinCoreField] = [.title, .creator, .publisher, .date, .language]
    var emoji: String {
        switch self {
        case .title: return "📘"
        case .creator: return "✍️"
        case .publisher: return "🏛️"
        case .date: return "📅"
        case .language: return "🌐"
        case .type: return "📚"
        case .format: return "📄"
        case .identifier: return "🔖"
        case .subject: return "🏷️"
        case .source: return "🔎"
        case .relation: return "🔗"
        case .description: return "📝"
        }
    }
    func color(for scheme: ColorScheme) -> Color? {
        let dark = scheme == .dark
        switch self {
        case .title: return Color(hex: dark ? 0x8BBCFF : 0x1769C2)
        case .creator: return Color(hex: dark ? 0xC4A4F5 : 0x7E49B0)
        case .publisher: return Color(hex: dark ? 0x7ED2BF : 0x24796D)
        case .date: return Color(hex: dark ? 0xF3BC76 : 0xA35D12)
        case .language: return Color(hex: dark ? 0xEEA1C0 : 0xB54172)
        default: return nil
        }
    }
}

struct RenameFileNameSegment {
    let value: String
    let field: DublinCoreField?
    static func segments(for name: String) -> [RenameFileNameSegment] {
        let suffix = name.lowercased().hasSuffix(".pdf") ? String(name.suffix(4)) : ""
        let base = String(name.dropLast(suffix.count))
        let tokens = base.components(separatedBy: "_")
        guard tokens.count == 5 else { return [RenameFileNameSegment(value: name, field: nil)] }
        var segments: [RenameFileNameSegment] = []
        for index in tokens.indices {
            if index > 0 { segments.append(RenameFileNameSegment(value: "_", field: nil)) }
            segments.append(RenameFileNameSegment(value: tokens[index], field: DublinCoreField.basicFields[index]))
        }
        if !suffix.isEmpty { segments.append(RenameFileNameSegment(value: suffix, field: nil)) }
        return segments
    }
}

struct RenameFileNamePreview: View {
    let fileName: String
    let palette: WorkspacePalette
    let language: AppLanguage
    var showsLegend = true
    @Environment(\.colorScheme) private var colorScheme
    private func text(_ key: AppTextKey) -> String { AppLocalization.text(key, language: language) }
    private var coloredName: Text {
        RenameFileNameSegment.segments(for: fileName).reduce(Text("")) { result, segment in
            result + Text(segment.value).foregroundColor(segment.field?.color(for: colorScheme) ?? palette.secondary)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            coloredName.font(.system(size: 14, weight: .medium)).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(fileName)
            if showsLegend {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), alignment: .leading)], alignment: .leading, spacing: 12) {
                    ForEach(DublinCoreField.basicFields, id: \.self) { field in
                        Text("\(field.emoji) \(text(field.labelKey))").font(.system(size: 11, weight: .medium))
                            .foregroundStyle(field.color(for: colorScheme) ?? palette.text)
                    }
                }
                if RenameFileNameSegment.segments(for: fileName).allSatisfy({ $0.field == nil }) {
                    Text(text(.customNameColorHint)).font(.system(size: 11)).foregroundStyle(palette.secondary)
                }
            }
        }.padding(14).background(palette.input.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RenamePromptState {
    let itemID: UUID
    let suggestedFileName: String
    var editableFileName: String
}

@MainActor
final class MainViewModel: ObservableObject {
    private static let languageDefaultsKey = "app.language.code"
    private static let appearanceDefaultsKey = "app.appearance.mode"

    @Published var language: AppLanguage
    @Published var appearanceMode: AppAppearanceMode
    @Published var sourcePath: String = ""
    @Published var items: [PDFWorkItem] = []
    @Published var selectedItemID: UUID?
    @Published var sourceOptions = MetadataSourceOptions()
    @Published var selectedDublinCoreFields: Set<DublinCoreField> = Set(DublinCoreField.defaultSelected)
    @Published var editableDublinCoreValues: [DublinCoreField: String] = [:]

    @Published var status: String
    @Published private(set) var statusIsError = false
    @Published var logs: [String] = []

    @Published var isSearching = false

    @Published var showWriteConfirmation = false
    @Published var pendingWriteSummary: String = ""
    @Published private(set) var pendingWritePreview: MetadataWritePreview?

    private var pendingWriteItemID: UUID?
    private var pendingWriteEntries: [String: String] = [:]
    @Published var renamePrompt: RenamePromptState?
    private var renamePrompts: [UUID: RenamePromptState] = [:]

    private struct EditableValuesContext: Hashable {
        let itemID: UUID
        let candidateID: UUID
    }

    private var editableValuesContext: EditableValuesContext?
    private var editableValuesCache: [EditableValuesContext: [DublinCoreField: String]] = [:]
    private var selectedSourceAccess: PDFSourceAccess?
    private var loadedSourceAccess: PDFSourceAccess?

    private let libraryService = PDFLibraryService()
    private let metadataService = MetadataService()
    private let fetcher = BookMetadataFetcher()
    private let renameService = BookRenameService()

    init() {
        let storedCode = UserDefaults.standard.string(forKey: Self.languageDefaultsKey)
        let initialLanguage = AppLanguage.from(code: storedCode) ?? AppLanguage.systemPreferred
        let storedAppearance = UserDefaults.standard.string(forKey: Self.appearanceDefaultsKey)
        let initialAppearance = AppAppearanceMode(rawValue: storedAppearance ?? "") ?? .light
        self.language = initialLanguage
        self.appearanceMode = initialAppearance
        AppLocalization.currentLanguage = initialLanguage
        self.status = AppLocalization.text(.statusReady, language: initialLanguage)
    }

    func text(_ key: AppTextKey) -> String {
        AppLocalization.text(key, language: language)
    }

    func format(_ key: AppTextKey, arguments: [CVarArg]) -> String {
        AppLocalization.format(key, language: language, arguments: arguments)
    }

    func setLanguage(_ newLanguage: AppLanguage) {
        guard newLanguage != language else { return }
        statusIsError = false
        language = newLanguage
        AppLocalization.currentLanguage = newLanguage
        UserDefaults.standard.set(newLanguage.rawValue, forKey: Self.languageDefaultsKey)

        status = format(.statusLanguageChanged, arguments: [newLanguage.nativeName])
        appendLog(status)
    }

    func setAppearanceMode(_ newMode: AppAppearanceMode) {
        guard newMode != appearanceMode else { return }
        statusIsError = false
        appearanceMode = newMode
        UserDefaults.standard.set(newMode.rawValue, forKey: Self.appearanceDefaultsKey)

        let modeText = text(newMode.textKey)
        status = format(.statusAppearanceChanged, arguments: [modeText])
        appendLog(status)
    }

    func appearanceModeLabel(_ mode: AppAppearanceMode) -> String {
        text(mode.textKey)
    }

    var preferredColorScheme: ColorScheme {
        appearanceMode.preferredColorScheme
    }

    var selectedItem: PDFWorkItem? {
        guard let selectedItemID,
              let item = items.first(where: { $0.id == selectedItemID })
        else {
            return nil
        }
        return item
    }

    var currentStageName: String {
        selectedItem?.stage.displayName ?? text(.stageNotStarted)
    }

    var currentStep: Int {
        guard let item = selectedItem else { return 1 }
        switch item.stage {
        case .loaded:
            return 2
        case .failed:
            if renamePrompt?.itemID == item.id { return 4 }
            return item.selectedCandidateID == nil ? 2 : 3
        case .searched:
            return 3
        case .written, .renamed, .renameSkipped:
            return 4
        }
    }

    var renamePromptFileName: String {
        renamePrompt?.editableFileName ?? ""
    }

    var hasSelectedSource: Bool {
        selectedSourceAccess?.urls.isEmpty == false
    }

    var saveItems: [PDFWorkItem] {
        items.filter { [.written, .renamed, .renameSkipped].contains($0.stage) || hasPendingRename(for: $0.id) }
    }

    func hasPendingRename(for id: UUID) -> Bool {
        renamePrompt?.itemID == id || renamePrompts[id] != nil
    }

    @discardableResult
    func pickSource() -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, !panel.urls.isEmpty {
            selectSources(panel.urls)
            return true
        }
        return false
    }

    func selectSources(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        selectedSourceAccess = PDFSourceAccess(urls: urls)
        sourcePath = urls.count == 1 ? urls[0].path : urls.map(\.lastPathComponent).joined(separator: "\n")
    }

    func loadPDFsFromSource() {
        statusIsError = false
        guard let sourceAccess = selectedSourceAccess else {
            statusIsError = true
            status = text(.statusSelectPDFFirst)
            appendLog(status)
            return
        }

        do {
            let pdfs = try libraryService.collectPDFs(from: sourceAccess.urls)
            items = pdfs.map { url in
                PDFWorkItem(url: url, hint: libraryService.buildHint(for: url))
            }
            loadedSourceAccess = sourceAccess
            selectedItemID = items.first?.id
            syncEditableDublinCoreValuesForSelection()
            renamePrompt = nil
            renamePrompts = [:]
            status = format(.statusLoadedCount, arguments: [items.count])
            appendLog(status)
        } catch {
            statusIsError = true
            status = format(.statusLoadFailed, arguments: [error.localizedDescription])
            appendLog(status)
        }
    }

    func selectItem(_ id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        if let prompt = renamePrompt { renamePrompts[prompt.itemID] = prompt }
        selectedItemID = id
        renamePrompt = renamePrompts[id]
        syncEditableDublinCoreValuesForSelection()
    }

    func searchHintFileName(for itemID: UUID) -> String {
        items.first(where: { $0.id == itemID })?.hint.fileNameTitle ?? ""
    }

    func searchHintExtractedTitle(for itemID: UUID) -> String {
        items.first(where: { $0.id == itemID })?.hint.extractedTitle ?? ""
    }

    func updateSearchHintFileName(_ value: String, for itemID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        let current = items[index].hint
        items[index].hint = rebuiltSearchHint(
            from: current,
            fileNameTitle: value,
            extractedTitle: current.extractedTitle
        )
    }

    func updateSearchHintExtractedTitle(_ value: String, for itemID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        let current = items[index].hint
        items[index].hint = rebuiltSearchHint(
            from: current,
            fileNameTitle: current.fileNameTitle,
            extractedTitle: value
        )
    }

    func searchMetadataForSelectedItem() {
        guard let item = selectedItem else {
            statusIsError = true
            status = text(.statusSelectPDFFirst)
            return
        }
        if isSearching {
            return
        }

        statusIsError = false
        isSearching = true
        status = format(.statusSearching, arguments: [item.url.lastPathComponent])
        appendLog(status)

        let itemID = item.id
        let hint = item.hint
        let options = sourceOptions

        Task {
            let candidates = await fetcher.fetchCandidates(hint: hint, options: options)

            guard let index = self.items.firstIndex(where: { $0.id == itemID }) else {
                self.isSearching = false
                return
            }

            self.items[index].candidates = candidates
            self.items[index].selectedCandidateID = candidates.first?.id
            if candidates.isEmpty {
                self.items[index].stage = .failed
                self.items[index].lastError = self.text(.statusNoMatch)
                self.statusIsError = true
                self.status = self.text(.statusNoMetadataFound)
            } else {
                self.items[index].stage = .searched
                self.status = self.format(.statusSearchComplete, arguments: [candidates.count])
            }
            if self.selectedItemID == itemID {
                self.syncEditableDublinCoreValuesForSelection()
            }
            self.appendLog(self.status)
            self.isSearching = false
        }
    }

    func chooseCandidate(_ candidateID: UUID, for itemID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].selectedCandidateID = candidateID
        if selectedItemID == itemID {
            syncEditableDublinCoreValuesForSelection()
        }
    }

    func setDublinCoreField(_ field: DublinCoreField, enabled: Bool) {
        if enabled {
            selectedDublinCoreFields.insert(field)
        } else {
            selectedDublinCoreFields.remove(field)
        }
    }

    func updateEditableDublinCoreValue(_ value: String, for field: DublinCoreField) {
        editableDublinCoreValues[field] = value
        guard let context = editableValuesContext else { return }
        editableValuesCache[context] = editableDublinCoreValues
    }

    func updateRenamePromptFileName(_ value: String) {
        guard var prompt = renamePrompt else { return }
        prompt.editableFileName = value
        renamePrompt = prompt
        renamePrompts[prompt.itemID] = prompt
    }

    func askWriteConfirmationForSelectedItem() {
        statusIsError = false
        guard let item = selectedItem,
              let candidate = selectedCandidate(for: item)
        else {
            statusIsError = true
            status = text(.statusSelectCandidate)
            return
        }

        guard !selectedDublinCoreFields.isEmpty else {
            statusIsError = true
            status = text(.statusSelectAtLeastOneField)
            appendLog(status)
            return
        }

        let entries = dublinCoreEntries(for: item, candidate: candidate).mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard entries.values.contains(where: { !$0.isEmpty }) else {
            statusIsError = true
            status = text(.statusNoNonemptyWriteValues)
            appendLog(status)
            return
        }
        let originals: [String: String]
        do {
            originals = try metadataService.readDublinCoreMetadata(for: item.url)
        } catch {
            cancelWriteConfirmation()
            statusIsError = true
            status = format(.statusMetadataReadFailed, arguments: [error.localizedDescription])
            appendLog(status)
            return
        }
        let preview = entries.sorted(by: { $0.key < $1.key }).map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        let rows = DublinCoreField.allCases.compactMap { field -> MetadataWritePreviewRow? in
            let original = originals[field.rawValue] ?? ""
            guard entries[field.rawValue] != nil || !original.isEmpty else { return nil }
            return MetadataWritePreviewRow(field: field, originalValue: original, proposedValue: entries[field.rawValue] ?? "", isSelectedForWrite: entries[field.rawValue] != nil)
        }
        pendingWritePreview = MetadataWritePreview(fileName: item.url.lastPathComponent, source: candidate.source, rows: rows)
        pendingWriteItemID = item.id
        pendingWriteEntries = entries
        pendingWriteSummary = format(.statusWritePreview, arguments: [preview])
        showWriteConfirmation = true
    }

    func cancelWriteConfirmation() {
        showWriteConfirmation = false
        pendingWriteItemID = nil
        pendingWriteEntries = [:]
        pendingWriteSummary = ""
        pendingWritePreview = nil
    }

    func performWriteConfirmed() {
        statusIsError = false
        guard let itemID = pendingWriteItemID,
              let index = items.firstIndex(where: { $0.id == itemID })
        else {
            statusIsError = true
            status = text(.statusWriteFailedMissingItem)
            appendLog(status)
            return
        }

        let url = items[index].url

        let entries = pendingWriteEntries
        guard !entries.isEmpty else {
            statusIsError = true
            status = text(.statusWriteFailedNoFields)
            appendLog(status)
            return
        }

        do {
            try metadataService.writeMetadata(fileURL: url, entries: entries)
            items[index].stage = .written
            status = format(.statusWriteSuccess, arguments: [url.lastPathComponent])
            appendLog(status)

            let suggested = renameService.suggestedFileName(forDublinCore: entries, originalExtension: url.pathExtension)
            let prompt = RenamePromptState(itemID: itemID, suggestedFileName: suggested, editableFileName: suggested)
            renamePrompts[itemID] = prompt
            if selectedItemID == itemID { renamePrompt = prompt }
        } catch {
            items[index].stage = .failed
            items[index].lastError = error.localizedDescription
            statusIsError = true
            status = format(.statusWriteFailed, arguments: [error.localizedDescription])
            appendLog(status)
        }

        pendingWriteItemID = nil
        pendingWriteEntries = [:]
        pendingWriteSummary = ""
        pendingWritePreview = nil
    }

    func confirmRenameForPrompt() {
        statusIsError = false
        guard let prompt = renamePrompt,
              let index = items.firstIndex(where: { $0.id == prompt.itemID })
        else {
            statusIsError = true
            status = text(.statusRenameMissingContext)
            appendLog(status)
            return
        }

        let oldURL = items[index].url
        let preferredName = prompt.editableFileName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? prompt.suggestedFileName : prompt.editableFileName
        guard let destinationURL = chooseRenameDestination(
            currentFileURL: oldURL,
            suggestedFileName: preferredName
        ) else {
            return
        }

        do {
            let newURL = try renameService.moveFile(at: oldURL, to: destinationURL)
            items[index].url = newURL
            items[index].stage = .renamed
            status = format(.statusRenameSuccess, arguments: [oldURL.lastPathComponent, newURL.lastPathComponent])
            appendLog(status)
            renamePrompts.removeValue(forKey: prompt.itemID)
            renamePrompt = nil
        } catch {
            items[index].stage = .failed
            items[index].lastError = error.localizedDescription
            statusIsError = true
            status = format(.statusRenameFailed, arguments: [error.localizedDescription])
            appendLog(status)
        }
    }

    func skipRenameForPrompt() {
        statusIsError = false
        guard let prompt = renamePrompt,
              let index = items.firstIndex(where: { $0.id == prompt.itemID })
        else {
            renamePrompt = nil
            return
        }

        renamePrompts.removeValue(forKey: prompt.itemID)
        items[index].stage = .renameSkipped
        status = format(.statusRenameSkipped, arguments: [items[index].url.lastPathComponent])
        appendLog(status)
        renamePrompt = nil
    }

    private func selectedCandidate(for item: PDFWorkItem) -> BookMetadataCandidate? {
        guard let id = item.selectedCandidateID else { return nil }
        return item.candidates.first(where: { $0.id == id })
    }

    private func chooseRenameDestination(currentFileURL: URL, suggestedFileName: String) -> URL? {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.canSelectHiddenExtension = true
        panel.isExtensionHidden = false
        panel.directoryURL = currentFileURL.deletingLastPathComponent()
        panel.nameFieldStringValue = suggestedFileName
        panel.allowedContentTypes = [UTType.pdf]

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url
    }

    private func rebuiltSearchHint(
        from base: PDFSearchHint,
        fileNameTitle: String,
        extractedTitle: String
    ) -> PDFSearchHint {
        let file = fileNameTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let extracted = extractedTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        var queryCandidates: [String] = []
        if let isbn = base.isbn?.trimmingCharacters(in: .whitespacesAndNewlines), !isbn.isEmpty {
            queryCandidates.append("isbn \(isbn)")
            queryCandidates.append(isbn)
        }
        if let doi = base.doi?.trimmingCharacters(in: .whitespacesAndNewlines), !doi.isEmpty {
            queryCandidates.append(doi)
        }
        if !extracted.isEmpty {
            queryCandidates.append(extracted)
        }
        if !file.isEmpty && file != extracted {
            queryCandidates.append(file)
        }

        let uniqueQueries = Array(NSOrderedSet(array: queryCandidates)) as? [String] ?? queryCandidates
        return PDFSearchHint(
            fileNameTitle: file,
            extractedTitle: extracted,
            snippet: base.snippet,
            isbn: base.isbn,
            doi: base.doi,
            queryCandidates: uniqueQueries
        )
    }

    func dublinCoreValueMap(for candidate: BookMetadataCandidate, fileURL: URL) -> [DublinCoreField: String] {
        let dcIdentifier: String = {
            if !candidate.isbn.isEmpty { return "isbn:\(candidate.isbn)" }
            if !candidate.doi.isEmpty { return "doi:\(candidate.doi)" }
            if !candidate.sourceURL.isEmpty { return candidate.sourceURL }
            return fileURL.lastPathComponent
        }()

        let typeSubject = candidate.kind == .paper ? "academic paper" : "book"
        let validationSummary = candidate.validatedBy.isEmpty ? "" : candidate.validatedBy.joined(separator: ", ")
        let description = [candidate.subtitle, validationSummary]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " | validation: ")

        return [
            .title: candidate.title,
            .creator: candidate.authorsText,
            .publisher: candidate.publisher,
            .date: candidate.publishedYear,
            .language: candidate.language,
            .type: "Text",
            .format: "application/pdf",
            .identifier: dcIdentifier,
            .source: candidate.source,
            .subject: typeSubject,
            .relation: candidate.sourceURL,
            .description: description
        ]
    }

    private func syncEditableDublinCoreValuesForSelection() {
        guard let item = selectedItem,
              let candidate = selectedCandidate(for: item)
        else {
            editableValuesContext = nil
            editableDublinCoreValues = [:]
            return
        }

        let context = EditableValuesContext(itemID: item.id, candidateID: candidate.id)
        editableValuesContext = context
        editableDublinCoreValues = editableValuesMap(for: item, candidate: candidate)
    }

    private func editableValuesMap(for item: PDFWorkItem, candidate: BookMetadataCandidate) -> [DublinCoreField: String] {
        let context = EditableValuesContext(itemID: item.id, candidateID: candidate.id)
        if let cached = editableValuesCache[context] {
            return cached
        }

        let generated = dublinCoreValueMap(for: candidate, fileURL: item.url)
        editableValuesCache[context] = generated
        return generated
    }

    private func dublinCoreEntries(for item: PDFWorkItem, candidate: BookMetadataCandidate) -> [String: String] {
        let all = currentEditableValues(for: item, candidate: candidate)

        var entries: [String: String] = [:]
        for field in DublinCoreField.allCases where selectedDublinCoreFields.contains(field) {
            entries[field.rawValue] = all[field] ?? ""
        }
        return entries
    }

    private func currentEditableValues(for item: PDFWorkItem, candidate: BookMetadataCandidate) -> [DublinCoreField: String] {
        let context = EditableValuesContext(itemID: item.id, candidateID: candidate.id)
        if context == editableValuesContext {
            return editableDublinCoreValues
        }
        return editableValuesMap(for: item, candidate: candidate)
    }

    private func appendLog(_ line: String) {
        logs.append("[\(DateFormatter.logTimestamp.string(from: Date()))] \(line)")
    }
}

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
