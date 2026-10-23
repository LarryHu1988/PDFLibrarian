import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }
    var localeIdentifier: String { rawValue }
    var nativeName: String { self == .simplifiedChinese ? "简体中文" : "English" }

    static var systemPreferred: AppLanguage {
        from(code: Locale.preferredLanguages.first) ?? .english
    }

    static func from(code: String?) -> AppLanguage? {
        guard let code else { return nil }
        let lower = code.lowercased()
        if lower.hasPrefix("zh") { return .simplifiedChinese }
        if lower.hasPrefix("en") { return .english }
        return nil
    }
}

enum AppTextKey {
    case currentFileMetadata
    case clearedValue
    case statusMetadataReadFailed
    case statusNoNonemptyWriteValues
    case fileNameColorPreview
    case suggestedFileNameLabel
    case customNameColorHint
    case validationSources
    case metadataField
    case modifiedFields
    case modifiedValue
    case writeHighlightHint
    case fileQueueHint
    case importSubtitle
    case selectFileForDetails
    case currentFile
    case lookupColumnHint
    case lookupOptions
    case selectCandidateForDetails
    case fieldColumnHint
    case basicFields
    case documentFields
    case additionalFields
    case includeField
    case saveColumnHint
    case noSaveItems
    case fileDetailsTitle
    case fileDetailsSubtitle
    case fileLocation
    case fileSize
    case pageCount
    case modifiedDate
    case lookupPreparation
    case candidateDetailsTitle
    case candidateDetailsSubtitle
    case editableValue
    case originalSourceValue
    case writeAllSelectedHint
    case lookupThisFile
    case useCandidateAndEdit
    case reviewAndWrite

    case themeBlue
    case themeWarm
    case themeGraphite
    case workspaceWelcome
    case importFiles
    case moreActions
    case workflowNavigation
    case currentBatch
    case batchEmpty
    case navigationFiles
    case navigationSearch
    case navigationEdit
    case navigationSave
    case completed
    case currentStepLabel
    case pending
    case settingsTitle
    case searchResults
    case allSources
    case filterResults
    case resultsEmptyTitle
    case resultsEmptyDetail
    case noFilteredResults
    case backToSearch
    case candidateHelp
    case selectedResult
    case chooseFileOrFolder
    case metadataSources
    case extractedSnippet
    case editMetadata
    case editorSubtitle
    case selectedFieldsShort
    case selectAllFields
    case currentSource
    case matchConfidence
    case openSource
    case moreFields
    case saveSubtitle
    case metadataWritten
    case fileComplete
    case writeFirst
    case startLookup
    case chooseSaveLocation
    case backToEditor
    case checkedFieldsOnly
    case fieldTitle
    case fieldAuthor
    case fieldPublisher
    case fieldYear
    case fieldLanguage
    case fieldType
    case fieldFormat
    case fieldIdentifier
    case fieldSubject
    case fieldSource
    case fieldRelation
    case fieldDescription

    case alertWriteTitle
    case buttonCancel
    case buttonConfirmWrite
    case appTitle
    case appSubtitle
    case chipPDFFiles
    case chipCurrentStatus
    case chipVersion
    case chipLanguage
    case chipAppearance
    case appearanceSystem
    case appearanceLightDay
    case appearanceDarkMoon
    case flowTitle
    case stepOne
    case stepTwo
    case stepThree
    case stepFour
    case cardOneTitle
    case fieldSelectedPath
    case fieldSelectedPathPlaceholder
    case buttonChoose
    case buttonLoadPDF
    case folderScanHint
    case loadedPDFList
    case noPDFLoaded
    case cardTwoTitle
    case hintFileName
    case hintExtractedTitle
    case hintFileNameLabel
    case hintExtractedTitleLabel
    case hintFileNamePlaceholder
    case hintExtractedTitlePlaceholder
    case hintISBN
    case hintDOI
    case hintSnippet
    case sourceOpenLibrary
    case sourceGoogleBooks
    case sourceDouban
    case sourceLOC
    case buttonSearchMetadata
    case buttonSearching
    case searchStrategy
    case noCandidates
    case loadAndSelectFirst
    case cardThreeTitle
    case selectedCandidate
    case sourceConfidence
    case noSelectedCandidate
    case dublinFieldsTitle
    case fieldValuePlaceholder
    case fieldCurrentValue
    case selectedFieldsCount
    case buttonConfirmWriteDublin
    case editableHint
    case cardFourTitle
    case suggestedFileName
    case renameFileNameLabel
    case renameFileNamePlaceholder
    case renameRule
    case renameRuleNote
    case buttonRename
    case buttonSkipRename
    case noRenamePrompt
    case executionLog
    case noLogs
    case contentHint
    case chipLanguageCode
    case chipValidated
    case stageNotStarted
    case stageLoaded
    case stageSearched
    case stageWritten
    case stageRenamed
    case stageRenameSkipped
    case stageFailed
    case publicationBook
    case publicationPaper
    case publicationUnknown
    case unknownAuthor
    case statusReady
    case statusLanguageChanged
    case statusAppearanceChanged
    case statusLoadedCount
    case statusLoadFailed
    case statusSelectPDFFirst
    case statusSearching
    case statusNoMatch
    case statusNoMetadataFound
    case statusSearchComplete
    case statusSelectCandidate
    case statusSelectAtLeastOneField
    case statusWritePreview
    case statusWriteFailedMissingItem
    case statusWriteFailedNoFields
    case statusWriteSuccess
    case statusWriteFailed
    case statusRenameMissingContext
    case statusRenameSuccess
    case statusRenameFailed
    case statusRenameSkipped
    case errorInvalidDirectory
    case errorInvalidFile
    case errorInvalidInput
    case errorReadFailure
    case errorWriteFailure
    case errorMoveFailure
    case errorNetworkFailure
}

enum AppLocalization {
    static var currentLanguage: AppLanguage = .simplifiedChinese

    static func text(_ key: AppTextKey, language: AppLanguage? = nil) -> String {
        let lang = language ?? currentLanguage

        if let workspace = workspaceText(key, language: lang) { return workspace }

        switch lang {
        case .simplifiedChinese:
            return chineseText(key)
        case .english:
            return englishText(key)

        }
    }

    static func format(_ key: AppTextKey, language: AppLanguage? = nil, arguments: [CVarArg]) -> String {
        let lang = language ?? currentLanguage
        let template = text(key, language: lang)
        return String(format: template, locale: Locale(identifier: lang.localeIdentifier), arguments: arguments)
    }

    private static func workspaceText(_ key: AppTextKey, language: AppLanguage) -> String? {
        let chinese = language == .simplifiedChinese
        switch key {
        case .currentFileMetadata: return chinese ? "文件当前值" : "Current file value"
        case .clearedValue: return chinese ? "清空" : "Clear"
        case .statusMetadataReadFailed: return chinese ? "无法读取文件当前元数据：%@" : "Could not read current file metadata: %@"
        case .statusNoNonemptyWriteValues: return chinese ? "请至少填写一个非空字段后再写入。" : "Enter at least one nonempty field before writing."
        case .fileNameColorPreview: return chinese ? "文件名颜色预览" : "Filename color preview"
        case .suggestedFileNameLabel: return chinese ? "建议文件名" : "Suggested filename"
        case .customNameColorHint: return chinese ? "自定义名称暂不分色；按“标题_作者_出版社_年份_语言”排列可显示对应颜色。" : "Custom names stay neutral. Use title_author_publisher_year_language to show field colors."
        case .validationSources: return chinese ? "校验来源" : "Validation sources"
        case .metadataField: return chinese ? "字段" : "Field"
        case .modifiedFields: return chinese ? "已修改" : "Modified"
        case .modifiedValue: return chinese ? "已修改" : "Modified"
        case .writeHighlightHint: return chinese ? "高亮表示与文件当前值不同的内容。“清空”行表示按现有写入规则将被移除的旧字段。确认后会清除旧元数据并写入已勾选字段。" : "Highlights show changes from the current file. Clear rows mark old fields removed by the write operation. Confirming clears old metadata and writes the checked fields."
        case .fileQueueHint: return chinese ? "文件已列在左侧。点击文件可回到它当前的处理步骤。" : "Your PDFs are listed in the sidebar. Select one to resume its current step."
        case .importSubtitle: return chinese ? "可一次选择多份 PDF 或文件夹，已选文件会显示在左栏。" : "Select multiple PDFs or folders. Selected files appear in the sidebar."
        case .selectFileForDetails: return chinese ? "选择文件查看详情" : "Select a file to see its details"
        case .currentFile: return chinese ? "当前文件" : "Current file"
        case .lookupColumnHint: return chinese ? "检索后选择一个结果，在右侧核对详细信息。" : "Look up records, then select a result to inspect on the right."
        case .lookupOptions: return chinese ? "检索条件与来源" : "Lookup hints and sources"
        case .selectCandidateForDetails: return chinese ? "选择结果查看详情" : "Select a result to inspect"
        case .fieldColumnHint: return chinese ? "勾选要写入的字段，点击字段在右侧编辑。" : "Check fields to include, then select a field to edit on the right."
        case .basicFields: return chinese ? "基本信息" : "BASIC DETAILS"
        case .documentFields: return chinese ? "文献信息" : "DOCUMENT DETAILS"
        case .additionalFields: return chinese ? "其他字段" : "ADDITIONAL FIELDS"
        case .includeField: return chinese ? "写入此字段" : "Include this field"
        case .saveColumnHint: return chinese ? "选择已写入元数据的文件，核对命名并保存。" : "Select a PDF with written metadata to review its name and save it."
        case .noSaveItems: return chinese ? "暂无可另存的文件" : "No PDFs ready to save"
        case .fileDetailsTitle: return chinese ? "文件详情" : "File details"
        case .fileDetailsSubtitle: return chinese ? "检查文件信息，为检索元数据做好准备。" : "Inspect this PDF before looking up its metadata."
        case .fileLocation: return chinese ? "所在文件夹" : "Folder"
        case .fileSize: return chinese ? "文件大小" : "File size"
        case .pageCount: return chinese ? "页数" : "Pages"
        case .modifiedDate: return chinese ? "修改日期" : "Modified"
        case .lookupPreparation: return chinese ? "检索准备" : "LOOKUP HINTS"
        case .candidateDetailsTitle: return chinese ? "候选详情" : "Record details"
        case .candidateDetailsSubtitle: return chinese ? "核对来源、作者与出版信息，再进入编辑。" : "Check the source, authors and publication details before editing."
        case .editableValue: return chinese ? "写入值" : "Value to write"
        case .originalSourceValue: return chinese ? "来源原始值" : "Original source value"
        case .writeAllSelectedHint: return chinese ? "确认时会核对并写入当前文件所有勾选字段，而不仅是正在编辑的字段。" : "Confirmation reviews and writes all checked fields for this PDF, including fields you are not currently editing."
        case .lookupThisFile: return chinese ? "检索这个文件" : "Look up this PDF"
        case .useCandidateAndEdit: return chinese ? "使用此结果并编辑" : "Use result and edit"
        case .reviewAndWrite: return chinese ? "核对并写入" : "Review and write"
        case .themeBlue: return chinese ? "清爽蓝白" : "Cool Blue"
        case .themeWarm: return chinese ? "暖白青绿" : "Warm Sage"
        case .themeGraphite: return chinese ? "石墨深色" : "Graphite"
        case .workspaceWelcome: return chinese ? "整理你的 PDF 书籍与文献" : "Organize your books and papers"
        case .importFiles: return chinese ? "导入 PDF" : "Import PDFs"
        case .moreActions: return chinese ? "更多操作" : "More actions"
        case .workflowNavigation: return chinese ? "工作流程" : "WORKFLOW"
        case .currentBatch: return chinese ? "当前批次" : "CURRENT BATCH"
        case .batchEmpty: return chinese ? "尚未导入 PDF，选择文件或文件夹开始整理。" : "Choose a PDF or folder to start your batch."
        case .navigationFiles: return chinese ? "导入文件" : "Import PDFs"
        case .navigationSearch: return chinese ? "检索书目" : "Find Metadata"
        case .navigationEdit: return chinese ? "编辑写入" : "Edit & Write"
        case .navigationSave: return chinese ? "另存命名" : "Save & Rename"
        case .completed: return chinese ? "已完成" : "Completed"
        case .currentStepLabel: return chinese ? "当前步骤" : "Current step"
        case .pending: return chinese ? "待处理" : "Pending"
        case .settingsTitle: return chinese ? "设置" : "Settings"
        case .searchResults: return chinese ? "检索结果" : "Results"
        case .allSources: return chinese ? "全部来源" : "All sources"
        case .filterResults: return chinese ? "筛选检索结果" : "Filter results"
        case .resultsEmptyTitle: return chinese ? "等待检索" : "Ready for lookup"
        case .resultsEmptyDetail: return chinese ? "导入 PDF 后，使用文件名和提取的标题检索书目信息。" : "Import a PDF, then look up its title and filename to find bibliographic records."
        case .noFilteredResults: return chinese ? "没有符合筛选条件的结果。" : "No results match your filter."
        case .backToSearch: return chinese ? "返回检索" : "Back to lookup"
        case .candidateHelp: return chinese ? "点击结果填入右侧字段" : "Select a result to fill the editor"
        case .selectedResult: return chinese ? "已选用" : "Selected"
        case .chooseFileOrFolder: return chinese ? "选择文件或文件夹…" : "Choose file or folder…"
        case .metadataSources: return chinese ? "检索来源" : "Lookup sources"
        case .extractedSnippet: return chinese ? "查看提取的内容" : "Extracted text"
        case .editMetadata: return chinese ? "编辑元数据" : "Edit metadata"
        case .editorSubtitle: return chinese ? "核对当前文件的书目信息。" : "Review the bibliographic details for this PDF."
        case .selectedFieldsShort: return chinese ? "已选" : "Selected"
        case .selectAllFields: return chinese ? "全选" : "Select all"
        case .currentSource: return chinese ? "当前选用来源" : "Selected source"
        case .matchConfidence: return chinese ? "匹配度" : "Match"
        case .openSource: return chinese ? "查看来源记录" : "Open source record"
        case .moreFields: return chinese ? "更多字段（3）" : "More fields (3)"
        case .saveSubtitle: return chinese ? "确认文件名后，选择保存位置完成重命名。" : "Review the filename, then choose where to save the renamed PDF."
        case .metadataWritten: return chinese ? "元数据已写入" : "Metadata written"
        case .fileComplete: return chinese ? "当前文件已完成" : "This PDF is complete"
        case .writeFirst: return chinese ? "请先确认并写入元数据" : "Write metadata first"
        case .startLookup: return chinese ? "开始检索" : "Start lookup"
        case .chooseSaveLocation: return chinese ? "选择保存位置…" : "Choose save location…"
        case .backToEditor: return chinese ? "返回编辑" : "Back to editor"
        case .checkedFieldsOnly: return chinese ? "仅写入勾选的字段" : "Only checked fields will be written"
        case .fieldTitle: return chinese ? "标题" : "Title"
        case .fieldAuthor: return chinese ? "作者" : "Authors"
        case .fieldPublisher: return chinese ? "出版社" : "Publisher"
        case .fieldYear: return chinese ? "出版年份" : "Year"
        case .fieldLanguage: return chinese ? "语言" : "Language"
        case .fieldType: return chinese ? "文献类型" : "Type"
        case .fieldFormat: return chinese ? "格式" : "Format"
        case .fieldIdentifier: return chinese ? "ISBN / DOI" : "ISBN / DOI"
        case .fieldSubject: return chinese ? "主题" : "Subject"
        case .fieldSource: return chinese ? "来源" : "Source"
        case .fieldRelation: return chinese ? "关联" : "Relation"
        case .fieldDescription: return chinese ? "描述" : "Description"
        default: return nil
        }
    }

    private static func englishText(_ key: AppTextKey) -> String {
        switch key {
        case .alertWriteTitle:
            return "Confirm metadata write?"
        case .buttonCancel:
            return "Cancel"
        case .buttonConfirmWrite:
            return "Confirm Write"
        case .appTitle:
            return "PDF Book/Paper Metadata Assistant"
        case .appSubtitle:
            return "4-step flow: choose PDF -> online lookup & merge -> confirm write -> save and rename"
        case .chipPDFFiles:
            return "PDF Files"
        case .chipCurrentStatus:
            return "Current Status"
        case .chipVersion:
            return "Version"
        case .chipLanguage:
            return "Language"
        case .chipAppearance:
            return "Theme"
        case .appearanceSystem:
            return "System"
        case .appearanceLightDay:
            return "Daylight"
        case .appearanceDarkMoon:
            return "Moonlight"
        case .flowTitle:
            return "Workflow Steps"
        case .stepOne:
            return "Select PDF"
        case .stepTwo:
            return "Lookup + Merge"
        case .stepThree:
            return "Confirm Dublin Core"
        case .stepFour:
            return "Ask & Rename"
        case .cardOneTitle:
            return "1) Select PDF"
        case .fieldSelectedPath:
            return "Selected Path"
        case .fieldSelectedPathPlaceholder:
            return "Use Choose to select a PDF file or folder"
        case .buttonChoose:
            return "Choose"
        case .buttonLoadPDF:
            return "Load PDF"
        case .folderScanHint:
            return "Choose opens the standard macOS dialog. If a folder is selected, all PDF files inside it are scanned recursively."
        case .loadedPDFList:
            return "Loaded PDF List"
        case .noPDFLoaded:
            return "No PDF loaded."
        case .cardTwoTitle:
            return "2) Online Lookup + Merge"
        case .hintFileName:
            return "Filename hint: %@"
        case .hintExtractedTitle:
            return "Extracted title hint: %@"
        case .hintFileNameLabel:
            return "Filename Hint"
        case .hintExtractedTitleLabel:
            return "Extracted Title Hint"
        case .hintFileNamePlaceholder:
            return "Edit filename hint for search"
        case .hintExtractedTitlePlaceholder:
            return "Edit extracted title hint for search"
        case .hintISBN:
            return "Detected ISBN: %@"
        case .hintDOI:
            return "Detected DOI: %@"
        case .hintSnippet:
            return "Content snippet: %@"
        case .sourceOpenLibrary:
            return "Open Library"
        case .sourceGoogleBooks:
            return "Google Books"
        case .sourceDouban:
            return "Douban Web Search"
        case .sourceLOC:
            return "Library of Congress"
        case .buttonSearchMetadata:
            return "Search Metadata Online"
        case .buttonSearching:
            return "Searching..."
        case .searchStrategy:
            return "Strategy: parallel sources -> ISBN/DOI/title+author dedupe -> field merge -> confidence rank"
        case .noCandidates:
            return "No candidate metadata yet. Run online search first."
        case .loadAndSelectFirst:
            return "Please load and select a PDF in Step 1 first."
        case .cardThreeTitle:
            return "3) Confirm Dublin Core Write"
        case .selectedCandidate:
            return "Selected candidate: %@"
        case .sourceConfidence:
            return "Source: %@ | Confidence: %d%%"
        case .noSelectedCandidate:
            return "No metadata candidate selected. Complete Step 2 first."
        case .dublinFieldsTitle:
            return "Dublin Core fields to write (selectable)"
        case .fieldValuePlaceholder:
            return "Field value"
        case .fieldCurrentValue:
            return "Current value: %@"
        case .selectedFieldsCount:
            return "%d fields selected"
        case .buttonConfirmWriteDublin:
            return "Confirm Write Dublin Core Metadata"
        case .editableHint:
            return "Values can be edited manually; write will use edited values."
        case .cardFourTitle:
            return "4) Ask and Rename"
        case .suggestedFileName:
            return "Suggested name: %@"
        case .renameFileNameLabel:
            return "Default file name for Save dialog"
        case .renameFileNamePlaceholder:
            return "Edit the suggested final file name"
        case .renameRule:
            return "Rule: title_author_publisher_year_language.pdf"
        case .renameRuleNote:
            return "The latest written metadata generates the default name; Confirm and Rename opens the standard macOS Save dialog so you can choose the final name and location."
        case .buttonRename:
            return "Choose Location & Rename"
        case .buttonSkipRename:
            return "Skip Rename"
        case .noRenamePrompt:
            return "No file is waiting for rename confirmation."
        case .executionLog:
            return "Execution Log"
        case .noLogs:
            return "No logs yet."
        case .contentHint:
            return "Content hint: %@"
        case .chipLanguageCode:
            return "Language: %@"
        case .chipValidated:
            return "Validation sources"
        case .stageNotStarted:
            return "Not Started"
        case .stageLoaded:
            return "Loaded"
        case .stageSearched:
            return "Searched"
        case .stageWritten:
            return "Written"
        case .stageRenamed:
            return "Renamed"
        case .stageRenameSkipped:
            return "Rename Skipped"
        case .stageFailed:
            return "Error"
        case .publicationBook:
            return "Book"
        case .publicationPaper:
            return "Paper"
        case .publicationUnknown:
            return "Unknown"
        case .unknownAuthor:
            return "Unknown Author"
        case .statusReady:
            return "Ready"
        case .statusLanguageChanged:
            return "Language switched to %@"
        case .statusAppearanceChanged:
            return "Theme switched to %@"
        case .statusLoadedCount:
            return "Loaded %d PDF(s)"
        case .statusLoadFailed:
            return "Load failed: %@"
        case .statusSelectPDFFirst:
            return "Please choose a PDF file or folder first"
        case .statusSearching:
            return "Searching online: %@"
        case .statusNoMatch:
            return "No matching metadata found"
        case .statusNoMetadataFound:
            return "No usable metadata found, try refining the file name and retry."
        case .statusSearchComplete:
            return "Search completed, found %d candidate metadata entries"
        case .statusSelectCandidate:
            return "Please select one metadata candidate first"
        case .statusSelectAtLeastOneField:
            return "Please select at least one Dublin Core field"
        case .statusWritePreview:
            return "The following Dublin Core fields will be written:\n%@\n\nContinue?"
        case .statusWriteFailedMissingItem:
            return "Write failed: pending item not found"
        case .statusWriteFailedNoFields:
            return "Write failed: no Dublin Core field selected"
        case .statusWriteSuccess:
            return "Dublin Core metadata written: %@"
        case .statusWriteFailed:
            return "Metadata write failed: %@"
        case .statusRenameMissingContext:
            return "Cannot rename: missing context"
        case .statusRenameSuccess:
            return "Rename succeeded: %@ -> %@"
        case .statusRenameFailed:
            return "Rename failed: %@"
        case .statusRenameSkipped:
            return "Rename skipped: %@"
        case .errorInvalidDirectory:
            return "Directory does not exist or is not accessible."
        case .errorInvalidFile:
            return "Please choose a PDF file or a folder containing PDFs."
        case .errorInvalidInput:
            return "Invalid input: %@"
        case .errorReadFailure:
            return "Read failed: %@"
        case .errorWriteFailure:
            return "Write failed: %@"
        case .errorMoveFailure:
            return "Move failed: %@ -> %@"
        case .errorNetworkFailure:
            return "Network request failed: %@"
        default: return workspaceText(key, language: .english) ?? ""
        }
    }

    private static func chineseText(_ key: AppTextKey) -> String {
        switch key {
        case .alertWriteTitle:
            return "确认写入元数据？"
        case .buttonCancel:
            return "取消"
        case .buttonConfirmWrite:
            return "确认写入"
        case .appTitle:
            return "PDF 书籍/文献元数据助手"
        case .appSubtitle:
            return "按 4 步流程处理：选择 PDF -> 联网检索与字段合并 -> 确认写入 -> 另存并重命名"
        case .chipPDFFiles:
            return "PDF 文件"
        case .chipCurrentStatus:
            return "当前状态"
        case .chipVersion:
            return "版本"
        case .chipLanguage:
            return "语言"
        case .chipAppearance:
            return "外观"
        case .appearanceSystem:
            return "跟随系统"
        case .appearanceLightDay:
            return "日光"
        case .appearanceDarkMoon:
            return "月光"
        case .flowTitle:
            return "流程步骤"
        case .stepOne:
            return "选择 PDF"
        case .stepTwo:
            return "联网检索+字段合并"
        case .stepThree:
            return "确认写入 Dublin Core"
        case .stepFour:
            return "询问并重命名"
        case .cardOneTitle:
            return "1) 选择 PDF"
        case .fieldSelectedPath:
            return "已选路径"
        case .fieldSelectedPathPlaceholder:
            return "请通过“选择”按钮打开系统面板并选择 PDF 文件或文件夹"
        case .buttonChoose:
            return "选择"
        case .buttonLoadPDF:
            return "加载 PDF"
        case .folderScanHint:
            return "“选择”会打开标准 macOS 文件面板；如果选择的是文件夹，程序会递归扫描其中所有 PDF。"
        case .loadedPDFList:
            return "已加载 PDF 列表"
        case .noPDFLoaded:
            return "尚未加载 PDF"
        case .cardTwoTitle:
            return "2) 联网检索+字段合并"
        case .hintFileName:
            return "文件名提示：%@"
        case .hintExtractedTitle:
            return "内容标题提示：%@"
        case .hintFileNameLabel:
            return "文件名提示"
        case .hintExtractedTitleLabel:
            return "内容标题提示"
        case .hintFileNamePlaceholder:
            return "可编辑后用于检索"
        case .hintExtractedTitlePlaceholder:
            return "可编辑后用于检索"
        case .hintISBN:
            return "检测到 ISBN：%@"
        case .hintDOI:
            return "检测到 DOI：%@"
        case .hintSnippet:
            return "内容片段：%@"
        case .sourceOpenLibrary:
            return "Open Library"
        case .sourceGoogleBooks:
            return "Google Books"
        case .sourceDouban:
            return "豆瓣网页搜索"
        case .sourceLOC:
            return "Library of Congress"
        case .buttonSearchMetadata:
            return "联网搜索元数据"
        case .buttonSearching:
            return "正在搜索..."
        case .searchStrategy:
            return "执行策略：多源并行 -> ISBN/DOI/标题作者去重 -> 字段合并 -> 置信度排序"
        case .noCandidates:
            return "还没有候选元数据，请先执行联网搜索。"
        case .loadAndSelectFirst:
            return "请先在第 1 步加载并选择一个 PDF。"
        case .cardThreeTitle:
            return "3) 确认写入 Dublin Core"
        case .selectedCandidate:
            return "当前选中候选：%@"
        case .sourceConfidence:
            return "来源：%@ | 置信度：%d%%"
        case .noSelectedCandidate:
            return "尚未选中候选元数据。请先完成第 2 步搜索并选择候选。"
        case .dublinFieldsTitle:
            return "Dublin Core 写入字段（可选择）"
        case .fieldValuePlaceholder:
            return "字段值"
        case .fieldCurrentValue:
            return "当前值：%@"
        case .selectedFieldsCount:
            return "已选 %d 个字段"
        case .buttonConfirmWriteDublin:
            return "确认写入 Dublin Core 元数据"
        case .editableHint:
            return "字段值可手动编辑；确认写入时将使用编辑后的值。"
        case .cardFourTitle:
            return "4) 询问并重命名"
        case .suggestedFileName:
            return "建议命名：%@"
        case .renameFileNameLabel:
            return "保存面板中的默认文件名"
        case .renameFileNamePlaceholder:
            return "可先编辑建议文件名，再打开保存面板"
        case .renameRule:
            return "规则：书名_作者_出版社_出版年_语言.pdf"
        case .renameRuleNote:
            return "命名将基于最新写入元数据生成；点击确认后会打开标准 macOS 保存面板，由你选择最终文件名和保存位置。"
        case .buttonRename:
            return "选择位置并重命名"
        case .buttonSkipRename:
            return "暂不重命名"
        case .noRenamePrompt:
            return "当前没有待确认重命名的文件。"
        case .executionLog:
            return "执行日志"
        case .noLogs:
            return "暂无日志"
        case .contentHint:
            return "内容提示：%@"
        case .chipLanguageCode:
            return "语言: %@"
        case .chipValidated:
            return "校验来源"
        case .stageNotStarted:
            return "未开始"
        case .stageLoaded:
            return "已加载"
        case .stageSearched:
            return "已检索"
        case .stageWritten:
            return "已写入"
        case .stageRenamed:
            return "已重命名"
        case .stageRenameSkipped:
            return "已跳过重命名"
        case .stageFailed:
            return "错误"
        case .publicationBook:
            return "书籍"
        case .publicationPaper:
            return "文献"
        case .publicationUnknown:
            return "未知"
        case .unknownAuthor:
            return "未知作者"
        case .statusReady:
            return "准备就绪"
        case .statusLanguageChanged:
            return "语言已切换为 %@"
        case .statusAppearanceChanged:
            return "外观已切换为 %@"
        case .statusLoadedCount:
            return "已加载 %d 个 PDF"
        case .statusLoadFailed:
            return "加载失败: %@"
        case .statusSelectPDFFirst:
            return "请先选择一个 PDF 文件或文件夹"
        case .statusSearching:
            return "正在联网检索: %@"
        case .statusNoMatch:
            return "未找到匹配元数据"
        case .statusNoMetadataFound:
            return "未找到可用元数据，建议调整文件名后重试"
        case .statusSearchComplete:
            return "检索完成，找到 %d 条候选元数据"
        case .statusSelectCandidate:
            return "请先选择一条候选元数据"
        case .statusSelectAtLeastOneField:
            return "请至少选择一个 Dublin Core 写入字段"
        case .statusWritePreview:
            return "将按 Dublin Core 写入以下字段：\n%@\n\n确认继续？"
        case .statusWriteFailedMissingItem:
            return "写入失败: 未找到待写入项"
        case .statusWriteFailedNoFields:
            return "写入失败: 没有选中任何 Dublin Core 字段"
        case .statusWriteSuccess:
            return "Dublin Core 元数据写入成功: %@"
        case .statusWriteFailed:
            return "元数据写入失败: %@"
        case .statusRenameMissingContext:
            return "无法执行重命名: 缺少上下文"
        case .statusRenameSuccess:
            return "重命名成功: %@ -> %@"
        case .statusRenameFailed:
            return "重命名失败: %@"
        case .statusRenameSkipped:
            return "已跳过重命名: %@"
        case .errorInvalidDirectory:
            return "目录不存在或不可访问。"
        case .errorInvalidFile:
            return "请选择 PDF 文件或包含 PDF 的目录。"
        case .errorInvalidInput:
            return "输入无效: %@"
        case .errorReadFailure:
            return "读取失败: %@"
        case .errorWriteFailure:
            return "写入失败: %@"
        case .errorMoveFailure:
            return "移动失败: %@ -> %@"
        case .errorNetworkFailure:
            return "网络请求失败: %@"
        default: return workspaceText(key, language: .simplifiedChinese) ?? ""
        }
    }

}
