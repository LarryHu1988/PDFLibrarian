import Foundation

struct BookRenameService {
    private let fileManager = FileManager.default

    func suggestedFileName(for candidate: BookMetadataCandidate, originalExtension: String = "pdf") -> String {
        let title = tokenOrFallback(candidate.title, fallback: "UnknownTitle")
        let author = tokenOrFallback(shortAuthorText(from: candidate.authors), fallback: "UnknownAuthor")
        let publisher = tokenOrFallback(candidate.publisher, fallback: "UnknownPublisher")
        let year = tokenOrFallback(candidate.publishedYear, fallback: "UnknownYear")
        let language = tokenOrFallback(candidate.language, fallback: "unknown")
        return suggestedFileName(
            title: title,
            author: author,
            publisher: publisher,
            year: year,
            language: language,
            originalExtension: originalExtension
        )
    }

    func suggestedFileName(forDublinCore entries: [String: String], originalExtension: String = "pdf") -> String {
        let title = tokenOrFallback(entries["dc:title"] ?? "", fallback: "UnknownTitle")
        let author = tokenOrFallback(entries["dc:creator"] ?? "", fallback: "UnknownAuthor")
        let publisher = tokenOrFallback(entries["dc:publisher"] ?? "", fallback: "UnknownPublisher")
        let year = tokenOrFallback(entries["dc:date"] ?? "", fallback: "UnknownYear")
        let language = tokenOrFallback(entries["dc:language"] ?? "", fallback: "unknown")
        return suggestedFileName(
            title: title,
            author: author,
            publisher: publisher,
            year: year,
            language: language,
            originalExtension: originalExtension
        )
    }

    func renameFile(at fileURL: URL, using candidate: BookMetadataCandidate) throws -> URL {
        let suggested = suggestedFileName(for: candidate, originalExtension: fileURL.pathExtension)
        return try renameFile(at: fileURL, to: suggested)
    }

    func renameFile(at fileURL: URL, to preferredFileName: String) throws -> URL {
        let finalFileName = try normalizePreferredFileName(
            preferredFileName,
            fallbackExtension: fileURL.pathExtension
        )
        let targetURL = uniqueURL(in: fileURL.deletingLastPathComponent(), fileName: finalFileName, excluding: fileURL)
        return try moveFile(at: fileURL, to: targetURL)
    }

    func moveFile(at fileURL: URL, to destinationURL: URL) throws -> URL {
        let finalDestinationURL = normalizedDestinationURL(
            destinationURL,
            fallbackExtension: fileURL.pathExtension
        )
        if isSameFileURL(finalDestinationURL, fileURL) {
            return fileURL
        }

        do {
            return try withSecurityScopedAccess(to: fileURL) {
                try withSecurityScopedAccess(to: finalDestinationURL.deletingLastPathComponent()) {
                    if fileManager.fileExists(atPath: finalDestinationURL.path) {
                        _ = try fileManager.replaceItemAt(
                            finalDestinationURL,
                            withItemAt: fileURL,
                            backupItemName: nil,
                            options: [.usingNewMetadataOnly]
                        )
                    } else {
                        try fileManager.moveItem(at: fileURL, to: finalDestinationURL)
                    }
                    return finalDestinationURL
                }
            }
        } catch {
            throw AppError.moveFailure(fileURL, finalDestinationURL)
        }
    }

    private func suggestedFileName(
        title: String,
        author: String,
        publisher: String,
        year: String,
        language: String,
        originalExtension: String
    ) -> String {
        let cleanTitle = sanitizeFieldToken(title)
        let cleanAuthor = sanitizeFieldToken(author)
        let cleanPublisher = sanitizeFieldToken(publisher)
        let cleanYear = sanitizeFieldToken(year)
        let cleanLanguage = sanitizeFieldToken(language)
        let base = [cleanTitle, cleanAuthor, cleanPublisher, cleanYear, cleanLanguage].joined(separator: "_")
        let sanitizedBase = sanitizeFileName(base)
        let ext = sanitizeExtension(originalExtension.isEmpty ? "pdf" : originalExtension)
        return ext.isEmpty ? sanitizedBase : "\(sanitizedBase).\(ext)"
    }

    private func normalizePreferredFileName(_ raw: String, fallbackExtension: String) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.invalidInput("重命名文件名不能为空")
        }

        let typedURL = URL(fileURLWithPath: trimmed)
        let typedExtension = typedURL.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        var typedBase = typedURL.deletingPathExtension().lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        if typedBase.isEmpty {
            typedBase = trimmed
        }

        let cleanBase = sanitizeFileName(typedBase)
        guard !cleanBase.isEmpty else {
            throw AppError.invalidInput("重命名文件名不能为空")
        }

        let ext = sanitizeExtension(typedExtension.isEmpty ? fallbackExtension : typedExtension)
        return ext.isEmpty ? cleanBase : "\(cleanBase).\(ext)"
    }

    private func sanitizeExtension(_ raw: String) -> String {
        let lowered = raw.lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let scalars = lowered.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(scalars))
    }

    private func shortAuthorText(from authors: [String]) -> String {
        let cleanAuthors = authors
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let first = cleanAuthors.first else {
            return "UnknownAuthor"
        }

        if cleanAuthors.count > 1 {
            return first
        }

        return first
    }

    private func uniqueURL(in directory: URL, fileName: String, excluding sourceURL: URL?) -> URL {
        let desired = directory.appendingPathComponent(fileName)
        if let sourceURL, isSameFileURL(desired, sourceURL) {
            return desired
        }
        if !fileManager.fileExists(atPath: desired.path) {
            return desired
        }

        let ext = desired.pathExtension
        let base = desired.deletingPathExtension().lastPathComponent
        var index = 1

        while true {
            let candidateName: String
            if ext.isEmpty {
                candidateName = "\(base)_\(index)"
            } else {
                candidateName = "\(base)_\(index).\(ext)"
            }
            let candidateURL = directory.appendingPathComponent(candidateName)
            if let sourceURL, isSameFileURL(candidateURL, sourceURL) {
                return candidateURL
            }
            if !fileManager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            index += 1
        }
    }

    private func normalizedDestinationURL(_ destinationURL: URL, fallbackExtension: String) -> URL {
        let directoryURL = destinationURL.deletingLastPathComponent()
        let rawBaseName = destinationURL
            .deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBaseName = sanitizeFileName(rawBaseName)
        let ext = sanitizeExtension(
            destinationURL.pathExtension.isEmpty ? fallbackExtension : destinationURL.pathExtension
        )
        let finalFileName = ext.isEmpty ? cleanBaseName : "\(cleanBaseName).\(ext)"
        return directoryURL.appendingPathComponent(finalFileName)
    }

    private func sanitizeFieldToken(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let converted = raw.unicodeScalars.map { invalid.contains($0) ? Character(".") : Character($0) }

        let sanitized = String(converted)
            .replacingOccurrences(of: "_", with: ".")
            .replacingOccurrences(of: "\\s+", with: ".", options: .regularExpression)
            .replacingOccurrences(of: "\\.+", with: ".", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "._ ").union(.whitespacesAndNewlines))

        return sanitized.isEmpty ? "Unknown" : sanitized
    }

    private func sanitizeFileName(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let converted = raw.unicodeScalars.map { invalid.contains($0) ? Character(".") : Character($0) }

        let sanitized = String(converted)
            .replacingOccurrences(of: "\\s+", with: ".", options: .regularExpression)
            .replacingOccurrences(of: "\\.+", with: ".", options: .regularExpression)
            .replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "._ ").union(.whitespacesAndNewlines))

        return sanitized.isEmpty ? "RenamedFile" : sanitized
    }

    private func tokenOrFallback(_ raw: String, fallback: String) -> String {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? fallback : clean
    }

    private func withSecurityScopedAccess<T>(to fileURL: URL, operation: () throws -> T) throws -> T {
        let didStartAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        return try operation()
    }

    private func isSameFileURL(_ lhs: URL, _ rhs: URL) -> Bool {
        lhs.standardizedFileURL.path == rhs.standardizedFileURL.path
    }
}
