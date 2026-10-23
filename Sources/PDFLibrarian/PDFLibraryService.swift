import Foundation
import PDFKit

struct PDFLibraryService {
    private let fileManager = FileManager.default

    func collectPDFs(from sourceURLs: [URL]) throws -> [URL] {
        var seen = Set<String>()
        var pdfs: [URL] = []
        for source in sourceURLs {
            for url in try collectPDFs(from: source) {
                let key = url.standardizedFileURL.resolvingSymlinksInPath().path
                if seen.insert(key).inserted { pdfs.append(url) }
            }
        }
        guard !pdfs.isEmpty else { throw AppError.invalidFile }
        return pdfs.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    func collectPDFs(from sourceURL: URL) throws -> [URL] {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDir) else {
            throw AppError.invalidFile
        }

        if !isDir.boolValue {
            guard sourceURL.pathExtension.lowercased() == "pdf" else {
                throw AppError.invalidFile
            }
            return [sourceURL]
        }

        let keys: [URLResourceKey] = [.isRegularFileKey, .isHiddenKey]
        guard let enumerator = fileManager.enumerator(
            at: sourceURL,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else {
            throw AppError.invalidDirectory
        }

        var pdfs: [URL] = []
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: Set(keys))
            guard values?.isRegularFile == true else { continue }
            if url.pathExtension.lowercased() == "pdf" {
                pdfs.append(url)
            }
        }

        if pdfs.isEmpty {
            throw AppError.invalidFile
        }

        return pdfs.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    func buildHint(for pdfURL: URL) -> PDFSearchHint {
        let fileNameTitle = normalizeFileName(pdfURL.deletingPathExtension().lastPathComponent)
        let previewText = extractPreviewText(pdfURL: pdfURL)
        let extractedTitle = detectLikelyTitle(from: previewText) ?? fileNameTitle
        let snippet = String(previewText.prefix(360)).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        let combined = fileNameTitle + "\n" + previewText
        let isbn = detectISBN(in: combined)
        let doi = detectDOI(in: combined)

        var queryCandidates: [String] = []
        if let isbn {
            queryCandidates.append("isbn \(isbn)")
            queryCandidates.append(isbn)
        }
        if let doi {
            queryCandidates.append(doi)
        }
        if !extractedTitle.isEmpty {
            queryCandidates.append(extractedTitle)
        }
        if !fileNameTitle.isEmpty && fileNameTitle != extractedTitle {
            queryCandidates.append(fileNameTitle)
        }

        let uniqueQueries = Array(NSOrderedSet(array: queryCandidates)) as? [String] ?? queryCandidates

        return PDFSearchHint(
            fileNameTitle: fileNameTitle,
            extractedTitle: extractedTitle,
            snippet: snippet,
            isbn: isbn,
            doi: doi,
            queryCandidates: uniqueQueries
        )
    }

    private func extractPreviewText(pdfURL: URL, maxPages: Int = 4) -> String {
        guard let document = PDFDocument(url: pdfURL) else { return "" }

        var text = ""
        let total = min(document.pageCount, maxPages)
        for index in 0..<total {
            if let page = document.page(at: index), let pageText = page.string {
                text += pageText
                text += "\n"
            }
        }

        if text.count > 6_000 {
            return String(text.prefix(6_000))
        }
        return text
    }

    private func normalizeFileName(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "[_\\-]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\[[^\\]]+\\]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\([^\\)]+\\)", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func detectLikelyTitle(from text: String) -> String? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for line in lines.prefix(30) {
            if line.count < 6 || line.count > 160 { continue }
            if line.rangeOfCharacter(from: .letters) == nil { continue }

            let alphaCount = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
            let digitCount = line.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }.count
            if digitCount > alphaCount { continue }
            return line
        }

        return nil
    }

    private func detectISBN(in text: String) -> String? {
        let pattern = #"(?i)\b(?:97[89][-\s]?)?[0-9][-0-9\s]{8,16}[0-9X]\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)

        for match in regex.matches(in: text, range: range) {
            guard let swiftRange = Range(match.range, in: text) else { continue }
            let raw = String(text[swiftRange])
            let normalized = raw
                .uppercased()
                .replacingOccurrences(of: "[^0-9X]", with: "", options: .regularExpression)
            if normalized.count == 10 || normalized.count == 13 {
                return normalized
            }
        }

        return nil
    }

    private func detectDOI(in text: String) -> String? {
        let pattern = #"(?i)\b10\.\d{4,9}/[-._;()/:A-Z0-9]+\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let swiftRange = Range(match.range, in: text)
        else {
            return nil
        }
        return String(text[swiftRange])
    }
}
