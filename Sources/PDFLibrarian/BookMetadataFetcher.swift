import Foundation

final class BookMetadataFetcher {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCandidates(hint: PDFSearchHint, options: MetadataSourceOptions) async -> [BookMetadataCandidate] {
        var pool: [BookMetadataCandidate] = []

        await withTaskGroup(of: [BookMetadataCandidate].self) { group in
            if options.useOpenLibrary {
                group.addTask { [self] in
                    await fetchFromOpenLibrary(hint: hint)
                }
            }

            if options.useGoogleBooks {
                group.addTask { [self] in
                    await fetchFromGoogleBooks(hint: hint)
                }
            }

            if options.useDoubanWebSearch {
                group.addTask { [self] in
                    await fetchFromDoubanWeb(hint: hint)
                }
            }

            if options.useLibraryOfCongress {
                group.addTask { [self] in
                    await fetchFromLibraryOfCongress(hint: hint)
                }
            }

            for await batch in group {
                pool.append(contentsOf: batch)
            }
        }

        return mergeAndRank(pool, hint: hint)
    }

    private func fetchFromOpenLibrary(hint: PDFSearchHint) async -> [BookMetadataCandidate] {
        var results: [BookMetadataCandidate] = []
        let queries = buildQueryStrings(from: hint, includeISBNToken: false, maxQueries: 3)

        var plans: [(items: [URLQueryItem], baseConfidence: Int)] = []
        if let isbn = hint.isbn, !normalizeISBN(isbn).isEmpty {
            plans.append(([
                URLQueryItem(name: "isbn", value: isbn),
                URLQueryItem(name: "limit", value: "8"),
                URLQueryItem(name: "fields", value: openLibraryFields)
            ], 64))
        }

        for query in queries {
            plans.append(([
                URLQueryItem(name: "title", value: query),
                URLQueryItem(name: "limit", value: "8"),
                URLQueryItem(name: "fields", value: openLibraryFields)
            ], 55))
        }

        for plan in plans {
            guard var comps = URLComponents(string: "https://openlibrary.org/search.json") else { continue }
            comps.queryItems = plan.items

            guard let url = comps.url,
                  let data = try? await requestData(url: url),
                  let payload = try? JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
            else {
                continue
            }

            for doc in payload.docs ?? [] {
                let title = cleanText(doc.title)
                guard !title.isEmpty else { continue }
                let sourceURL = doc.key.map { "https://openlibrary.org\($0)" } ?? ""

                results.append(
                    BookMetadataCandidate(
                        kind: .book,
                        title: title,
                        subtitle: cleanText(doc.subtitle),
                        authors: sanitizeAuthors(doc.authorName ?? []),
                        publisher: cleanText(doc.publisher?.first),
                        publishedYear: doc.firstPublishYear.map(String.init) ?? "",
                        language: normalizeLanguage(doc.language?.first ?? ""),
                        isbn: normalizeISBN(doc.isbn?.first ?? ""),
                        doi: "",
                        source: "Open Library",
                        sourceURL: sourceURL,
                        validatedBy: ["Open Library"],
                        confidence: plan.baseConfidence
                    )
                )
            }
        }

        return results
    }

    private func fetchFromGoogleBooks(hint: PDFSearchHint) async -> [BookMetadataCandidate] {
        var results: [BookMetadataCandidate] = []
        var queries = buildQueryStrings(from: hint, includeISBNToken: false, maxQueries: 3)

        if let isbn = hint.isbn, !normalizeISBN(isbn).isEmpty {
            queries.insert("isbn:\(normalizeISBN(isbn))", at: 0)
        }

        for query in uniquePreservingOrder(queries) {
            guard var comps = URLComponents(string: "https://www.googleapis.com/books/v1/volumes") else { continue }
            comps.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "maxResults", value: "8"),
                URLQueryItem(name: "printType", value: "books")
            ]

            guard let url = comps.url,
                  let data = try? await requestData(url: url),
                  let payload = try? JSONDecoder().decode(GoogleVolumesResponse.self, from: data)
            else {
                continue
            }

            for item in payload.items ?? [] {
                guard let info = item.volumeInfo else {
                    continue
                }

                let title = cleanText(info.title)
                guard !title.isEmpty else {
                    continue
                }

                results.append(
                    BookMetadataCandidate(
                        kind: .book,
                        title: title,
                        subtitle: cleanText(info.subtitle),
                        authors: sanitizeAuthors(info.authors ?? []),
                        publisher: cleanText(info.publisher),
                        publishedYear: firstYear(in: info.publishedDate) ?? "",
                        language: normalizeLanguage(info.language ?? ""),
                        isbn: bestGoogleISBN(info.industryIdentifiers),
                        doi: "",
                        source: "Google Books",
                        sourceURL: cleanText(info.infoLink),
                        validatedBy: ["Google Books"],
                        confidence: 50
                    )
                )
            }
        }

        return results
    }

    private func fetchFromDoubanWeb(hint: PDFSearchHint) async -> [BookMetadataCandidate] {
        var results: [BookMetadataCandidate] = []
        var queries = buildQueryStrings(from: hint, includeISBNToken: false, maxQueries: 3)
        if let isbn = hint.isbn, !normalizeISBN(isbn).isEmpty {
            queries.insert(isbn, at: 0)
        }

        for query in uniquePreservingOrder(queries) {
            guard var comps = URLComponents(string: "https://book.douban.com/subject_search") else { continue }
            comps.queryItems = [
                URLQueryItem(name: "search_text", value: query),
                URLQueryItem(name: "cat", value: "1001")
            ]

            guard let url = comps.url else { continue }

            let browserHeaders = [
                "User-Agent": browserUserAgent,
                "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8"
            ]

            guard let data = try? await requestData(url: url, headers: browserHeaders),
                  let html = String(data: data, encoding: .utf8),
                  let payloadData = extractDoubanDataJSON(from: html),
                  let payloadObject = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
                  let items = payloadObject["items"] as? [[String: Any]]
            else {
                continue
            }

            for item in items.prefix(10) {
                let title = cleanText(firstString(from: item["title"]))
                if title.isEmpty { continue }

                let abstract = cleanText(firstString(from: item["abstract"]))
                let parsed = parseDoubanAbstract(abstract)
                let sourceURL = cleanText(firstString(from: item["url"]))

                results.append(
                    BookMetadataCandidate(
                        kind: .book,
                        title: title,
                        subtitle: "",
                        authors: parsed.authors,
                        publisher: parsed.publisher,
                        publishedYear: parsed.publishedYear,
                        language: parsed.language,
                        isbn: parsed.isbn,
                        doi: "",
                        source: "豆瓣",
                        sourceURL: sourceURL,
                        validatedBy: ["Douban"],
                        confidence: 42
                    )
                )
            }
        }

        return results
    }

    private func fetchFromLibraryOfCongress(hint: PDFSearchHint) async -> [BookMetadataCandidate] {
        var results: [BookMetadataCandidate] = []
        var queries = buildQueryStrings(from: hint, includeISBNToken: false, maxQueries: 3)
        if let isbn = hint.isbn, !normalizeISBN(isbn).isEmpty {
            queries.insert("isbn \(isbn)", at: 0)
        }

        for query in uniquePreservingOrder(queries) {
            guard var comps = URLComponents(string: "https://www.loc.gov/books/") else { continue }
            comps.queryItems = [
                URLQueryItem(name: "fo", value: "json"),
                URLQueryItem(name: "q", value: query)
            ]

            guard let url = comps.url,
                  let data = try? await requestData(url: url),
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                continue
            }

            let items = locResults(from: root)
            for raw in items.prefix(10) {
                let item = raw["item"] as? [String: Any]
                let title = cleanText(firstString(from: raw["title"]) ?? firstString(from: item?["title"]))
                if title.isEmpty { continue }

                let contributors = stringArray(from: raw["contributor"])
                let itemContributors = stringArray(from: item?["contributors"])
                let authors = sanitizeAuthors(contributors + itemContributors)

                let createdPublishedList = stringArray(from: item?["created_published"])
                let createdPublished = createdPublishedList.first ?? ""
                let publisher = parsePublisherFromCreatedPublished(createdPublished)
                let publishedYear = firstYear(in: cleanText(firstString(from: raw["date"]))) ?? firstYear(in: createdPublished) ?? ""
                let language = normalizeLanguage(stringArray(from: raw["language"]).first ?? stringArray(from: item?["language"]).first ?? "")
                let sourceURL = cleanText(firstString(from: raw["url"]) ?? firstString(from: raw["id"]))
                let isbn = extractISBNRecursively(raw)

                results.append(
                    BookMetadataCandidate(
                        kind: .book,
                        title: title,
                        subtitle: "",
                        authors: authors,
                        publisher: publisher,
                        publishedYear: publishedYear,
                        language: language,
                        isbn: isbn,
                        doi: "",
                        source: "Library of Congress",
                        sourceURL: sourceURL,
                        validatedBy: ["LoC"],
                        confidence: 48
                    )
                )
            }
        }

        return results
    }

    private func mergeAndRank(_ rawCandidates: [BookMetadataCandidate], hint: PDFSearchHint) -> [BookMetadataCandidate] {
        var grouped: [String: [BookMetadataCandidate]] = [:]

        for raw in rawCandidates {
            var candidate = normalizedCandidate(raw)
            guard !candidate.title.isEmpty else { continue }
            candidate.confidence = score(candidate: candidate, hint: hint)
            let key = dedupeKey(for: candidate)
            grouped[key, default: []].append(candidate)
        }

        var merged: [BookMetadataCandidate] = []

        for group in grouped.values {
            let sorted = group.sorted {
                if $0.confidence == $1.confidence {
                    return $0.primaryTitle.localizedCaseInsensitiveCompare($1.primaryTitle) == .orderedAscending
                }
                return $0.confidence > $1.confidence
            }

            guard var base = sorted.first else { continue }
            var sourceList = uniquePreservingOrder(sorted.map(\.source))
            var validations = Set(base.validatedBy)
            var strongest = base.confidence

            for entry in sorted.dropFirst() {
                strongest = max(strongest, entry.confidence)
                base.kind = mergeKind(base.kind, entry.kind)
                base.title = betterText(base.title, entry.title)
                base.subtitle = betterText(base.subtitle, entry.subtitle)
                base.authors = mergeAuthors(base.authors, entry.authors)
                base.publisher = betterText(base.publisher, entry.publisher)
                base.publishedYear = betterYear(base.publishedYear, entry.publishedYear)
                base.language = betterLanguage(base.language, entry.language)
                base.isbn = betterISBN(base.isbn, entry.isbn)
                base.doi = betterDOI(base.doi, entry.doi)
                base.sourceURL = betterURL(base.sourceURL, entry.sourceURL)
                sourceList = uniquePreservingOrder(sourceList + sourceNames(from: entry.source))
                validations.formUnion(entry.validatedBy)
            }

            if base.language.isEmpty {
                base.language = inferLanguage(from: "\(base.title) \(base.subtitle)")
            }

            let sourceBonus = min(12, max(0, sourceList.count - 1) * 3)
            base.source = sourceList.joined(separator: " + ")
            base.validatedBy = Array(validations).sorted()
            base.confidence = min(99, strongest + sourceBonus)
            merged.append(base)
        }

        return merged.sorted {
            if $0.confidence == $1.confidence {
                return $0.primaryTitle.localizedCaseInsensitiveCompare($1.primaryTitle) == .orderedAscending
            }
            return $0.confidence > $1.confidence
        }
    }

    private func normalizedCandidate(_ candidate: BookMetadataCandidate) -> BookMetadataCandidate {
        BookMetadataCandidate(
            kind: candidate.kind,
            title: cleanText(candidate.title),
            subtitle: cleanText(candidate.subtitle),
            authors: sanitizeAuthors(candidate.authors),
            publisher: cleanText(candidate.publisher),
            publishedYear: firstYear(in: candidate.publishedYear) ?? cleanText(candidate.publishedYear),
            language: normalizeLanguage(candidate.language),
            isbn: normalizeISBN(candidate.isbn),
            doi: normalizeDOI(candidate.doi),
            source: cleanText(candidate.source),
            sourceURL: cleanText(candidate.sourceURL),
            validatedBy: uniquePreservingOrder(candidate.validatedBy.map(cleanText)),
            confidence: candidate.confidence
        )
    }

    private func score(candidate: BookMetadataCandidate, hint: PDFSearchHint) -> Int {
        var score = candidate.confidence

        let normalizedTitle = normalizeForCompare(candidate.primaryTitle)
        let localTitle = normalizeForCompare(hint.extractedTitle)
        let fileTitle = normalizeForCompare(hint.fileNameTitle)
        let snippet = normalizeForCompare(hint.snippet)

        if !localTitle.isEmpty,
           normalizedTitle.contains(localTitle) || localTitle.contains(normalizedTitle) {
            score += 18
        } else if !fileTitle.isEmpty,
                  normalizedTitle.contains(fileTitle) || fileTitle.contains(normalizedTitle) {
            score += 12
        } else if !snippet.isEmpty, snippet.contains(normalizedTitle), normalizedTitle.count > 5 {
            score += 8
        }

        let hintISBN = normalizeISBN(hint.isbn ?? "")
        let candidateISBN = normalizeISBN(candidate.isbn)
        if !hintISBN.isEmpty, !candidateISBN.isEmpty, hintISBN == candidateISBN {
            score += 32
        }

        let hintDOI = normalizeDOI(hint.doi ?? "")
        let candidateDOI = normalizeDOI(candidate.doi)
        if !hintDOI.isEmpty, !candidateDOI.isEmpty, hintDOI == candidateDOI {
            score += 26
        }

        if !candidate.authors.isEmpty { score += 4 }
        if !candidate.publisher.isEmpty { score += 3 }
        if !candidate.publishedYear.isEmpty { score += 3 }
        if !candidate.language.isEmpty { score += 2 }

        return min(max(score, 10), 99)
    }

    private func dedupeKey(for candidate: BookMetadataCandidate) -> String {
        let isbn = normalizeISBN(candidate.isbn)
        if !isbn.isEmpty {
            return "isbn|\(isbn)"
        }

        let doi = normalizeDOI(candidate.doi)
        if !doi.isEmpty {
            return "doi|\(doi)"
        }

        let title = normalizeForCompare(candidate.primaryTitle)
        let author = normalizeForCompare(candidate.authors.first ?? "")
        let year = firstYear(in: candidate.publishedYear) ?? ""
        return "title|\(title)|\(author)|\(year)"
    }

    private func locResults(from root: [String: Any]) -> [[String: Any]] {
        if let content = root["content"] as? [String: Any],
           let results = content["results"] as? [[String: Any]] {
            return results
        }

        if let results = root["results"] as? [[String: Any]] {
            return results
        }

        return []
    }

    private func parsePublisherFromCreatedPublished(_ raw: String) -> String {
        let clean = cleanText(raw)
        if clean.isEmpty { return "" }

        let pattern = #":\s*(.+?)(?:,|\.)\s*(?:1[5-9][0-9]{2}|20[0-9]{2}|21[0-9]{2})"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)),
           let range = Range(match.range(at: 1), in: clean) {
            return cleanText(String(clean[range]))
        }

        return ""
    }

    private func parseDoubanAbstract(_ abstract: String) -> ParsedDoubanAbstract {
        let clean = cleanText(abstract)
        if clean.isEmpty {
            return ParsedDoubanAbstract(authors: [], publisher: "", publishedYear: "", isbn: "", language: "")
        }

        let tokens = clean
            .split(separator: "/")
            .map { cleanText(String($0)) }
            .filter { !$0.isEmpty }

        let year = firstYear(in: clean) ?? ""
        let isbn = extractISBN(in: clean)
        let language = inferLanguage(from: clean)

        var yearIndex: Int?
        for (idx, token) in tokens.enumerated() {
            if firstYear(in: token) != nil {
                yearIndex = idx
                break
            }
        }

        var publisher = ""
        var authors: [String] = []

        if let yearIndex, yearIndex > 0 {
            publisher = tokens[yearIndex - 1]
            if yearIndex >= 2 {
                authors = Array(tokens[0..<(yearIndex - 1)])
            }
        } else if tokens.count >= 3 {
            publisher = tokens[tokens.count - 2]
            authors = Array(tokens.prefix(tokens.count - 2))
        } else if tokens.count == 2 {
            authors = [tokens[0]]
            publisher = tokens[1]
        } else if tokens.count == 1 {
            authors = [tokens[0]]
        }

        let normalizedAuthors = sanitizeAuthors(authors)
        let publisherFromAuthors = normalizedAuthors.contains(publisher) ? "" : publisher

        return ParsedDoubanAbstract(
            authors: normalizedAuthors,
            publisher: cleanText(publisherFromAuthors),
            publishedYear: year,
            isbn: isbn,
            language: language
        )
    }

    private func extractDoubanDataJSON(from html: String) -> Data? {
        let pattern = #"window\.__DATA__\s*=\s*(\{.*?\})\s*;"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.dotMatchesLineSeparators]
        ) else {
            return nil
        }

        let nsRange = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: nsRange),
              let range = Range(match.range(at: 1), in: html)
        else {
            return nil
        }

        let jsonText = String(html[range])
        return jsonText.data(using: .utf8)
    }

    private func firstString(from value: Any?) -> String? {
        guard let value else { return nil }

        if let text = value as? String {
            let clean = cleanText(text)
            return clean.isEmpty ? nil : clean
        }

        if let number = value as? NSNumber {
            return number.stringValue
        }

        if let array = value as? [Any] {
            for element in array {
                if let found = firstString(from: element) {
                    return found
                }
            }
        }

        if let dict = value as? [String: Any] {
            for key in ["name", "value", "text", "label", "title", "id"] {
                if let found = firstString(from: dict[key]) {
                    return found
                }
            }
        }

        return nil
    }

    private func stringArray(from value: Any?) -> [String] {
        guard let value else { return [] }

        if let text = value as? String {
            let clean = cleanText(text)
            return clean.isEmpty ? [] : [clean]
        }

        if let array = value as? [String] {
            return array.map(cleanText).filter { !$0.isEmpty }
        }

        if let array = value as? [Any] {
            return array.compactMap { firstString(from: $0) }.map(cleanText).filter { !$0.isEmpty }
        }

        return []
    }

    private func extractISBNRecursively(_ value: Any?) -> String {
        guard let value else { return "" }

        if let text = value as? String {
            return extractISBN(in: text)
        }

        if let array = value as? [Any] {
            for item in array {
                let found = extractISBNRecursively(item)
                if !found.isEmpty {
                    return found
                }
            }
        }

        if let dict = value as? [String: Any] {
            for item in dict.values {
                let found = extractISBNRecursively(item)
                if !found.isEmpty {
                    return found
                }
            }
        }

        return ""
    }

    private func extractISBN(in text: String) -> String {
        let pattern = #"(97[89][0-9]{10}|[0-9]{9}[0-9Xx])"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else {
            return ""
        }

        return normalizeISBN(String(text[range]))
    }

    private func buildQueryStrings(
        from hint: PDFSearchHint,
        includeISBNToken: Bool,
        maxQueries: Int
    ) -> [String] {
        var queries: [String] = []

        let extracted = cleanText(hint.extractedTitle)
        if !extracted.isEmpty {
            queries.append(extracted)
        }

        let file = cleanText(hint.fileNameTitle)
        if !file.isEmpty {
            queries.append(file)
        }

        queries.append(contentsOf: hint.queryCandidates.map(cleanText))

        if includeISBNToken, let isbn = hint.isbn {
            let normalized = normalizeISBN(isbn)
            if !normalized.isEmpty {
                queries.append(normalized)
            }
        }

        return Array(uniquePreservingOrder(queries).prefix(maxQueries))
    }

    private func sanitizeAuthors(_ raw: [String]) -> [String] {
        let cleaned = raw
            .map(cleanText)
            .flatMap { text -> [String] in
                if text.contains(" / ") {
                    return text.split(separator: "/").map { cleanText(String($0)) }
                }
                return [text]
            }
            .filter { !$0.isEmpty && $0.count <= 80 }

        return uniquePreservingOrder(cleaned)
    }

    private func sourceNames(from source: String) -> [String] {
        source
            .split(separator: "+")
            .map { cleanText(String($0)) }
            .filter { !$0.isEmpty }
    }

    private func mergeKind(_ left: PublicationKind, _ right: PublicationKind) -> PublicationKind {
        if left == right { return left }
        if left == .unknown { return right }
        if right == .unknown { return left }
        if left == .book || right == .book { return .book }
        return .paper
    }

    private func mergeAuthors(_ left: [String], _ right: [String]) -> [String] {
        uniquePreservingOrder(sanitizeAuthors(left + right))
    }

    private func betterText(_ left: String, _ right: String) -> String {
        let l = cleanText(left)
        let r = cleanText(right)
        if l.isEmpty { return r }
        if r.isEmpty { return l }
        if l.count >= r.count { return l }
        return r
    }

    private func betterYear(_ left: String, _ right: String) -> String {
        let l = firstYear(in: left) ?? ""
        let r = firstYear(in: right) ?? ""
        if l.isEmpty { return r }
        if r.isEmpty { return l }
        return l
    }

    private func betterLanguage(_ left: String, _ right: String) -> String {
        let l = normalizeLanguage(left)
        let r = normalizeLanguage(right)
        if l.isEmpty { return r }
        if r.isEmpty { return l }
        return l
    }

    private func betterISBN(_ left: String, _ right: String) -> String {
        let l = normalizeISBN(left)
        let r = normalizeISBN(right)
        if l.isEmpty { return r }
        if r.isEmpty { return l }
        if l.count >= r.count { return l }
        return r
    }

    private func betterDOI(_ left: String, _ right: String) -> String {
        let l = normalizeDOI(left)
        let r = normalizeDOI(right)
        if l.isEmpty { return r }
        if r.isEmpty { return l }
        if l.count <= r.count { return l }
        return r
    }

    private func betterURL(_ left: String, _ right: String) -> String {
        let l = cleanText(left)
        let r = cleanText(right)
        if l.isEmpty { return r }
        return l
    }

    private func inferLanguage(from text: String) -> String {
        if text.range(of: #"\p{Han}"#, options: .regularExpression) != nil {
            return "zh"
        }
        if text.range(of: "[A-Za-z]", options: .regularExpression) != nil {
            return "en"
        }
        return ""
    }

    private func cleanText(_ value: String?) -> String {
        (value ?? "")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizeLanguage(_ raw: String) -> String {
        let clean = raw
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.isEmpty { return "" }

        if clean.contains("/languages/") {
            return String(clean.split(separator: "/").last ?? "")
        }

        let mapping: [String: String] = [
            "eng": "en",
            "english": "en",
            "fre": "fr",
            "fra": "fr",
            "spa": "es",
            "ger": "de",
            "deu": "de",
            "chi": "zh",
            "zho": "zh",
            "chinese": "zh",
            "jpn": "ja",
            "japanese": "ja"
        ]

        return mapping[clean] ?? clean
    }

    private func normalizeDOI(_ raw: String) -> String {
        let clean = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://doi.org/", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "doi:", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.lowercased()
    }

    private func bestGoogleISBN(_ identifiers: [GoogleIndustryIdentifier]?) -> String {
        let all = identifiers ?? []

        if let isbn13 = all.first(where: { ($0.type ?? "").uppercased().contains("ISBN_13") })?.identifier {
            return normalizeISBN(isbn13)
        }

        if let isbn10 = all.first(where: { ($0.type ?? "").uppercased().contains("ISBN_10") })?.identifier {
            return normalizeISBN(isbn10)
        }

        return ""
    }

    private func normalizeForCompare(_ raw: String) -> String {
        raw
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\p{Han}]", with: "", options: .regularExpression)
    }

    private func firstYear(in raw: String?) -> String? {
        guard let raw else { return nil }
        let pattern = #"(1[5-9][0-9]{2}|20[0-9]{2}|21[0-9]{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(raw.startIndex..., in: raw)
        guard let match = regex.firstMatch(in: raw, range: range),
              let swiftRange = Range(match.range(at: 1), in: raw)
        else {
            return nil
        }
        return String(raw[swiftRange])
    }

    private func normalizeISBN(_ raw: String) -> String {
        raw
            .uppercased()
            .replacingOccurrences(of: "[^0-9X]", with: "", options: .regularExpression)
    }

    private func uniquePreservingOrder(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for value in values {
            let clean = cleanText(value)
            if clean.isEmpty { continue }
            let key = clean.lowercased()
            if seen.insert(key).inserted {
                ordered.append(clean)
            }
        }
        return ordered
    }

    private func requestData(url: URL, headers: [String: String] = [:]) async throws -> Data {
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.setValue(userAgentValue, forHTTPHeaderField: "User-Agent")
        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }
        return try await requestData(request: req)
    }

    private func requestData(request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkFailure(request.url?.absoluteString ?? "")
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = "\(request.url?.absoluteString ?? "") [HTTP \(http.statusCode)]"
            throw AppError.networkFailure(message)
        }

        return data
    }

    private let openLibraryFields = [
        "title",
        "subtitle",
        "author_name",
        "first_publish_year",
        "publisher",
        "isbn",
        "language",
        "key"
    ].joined(separator: ",")

    private let browserUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36"

    private var userAgentValue: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? shortVersion

        if buildVersion.isEmpty || buildVersion == shortVersion {
            return "PDFLibrarian/\(shortVersion)"
        }

        return "PDFLibrarian/\(shortVersion) (\(buildVersion))"
    }
}

private struct ParsedDoubanAbstract {
    let authors: [String]
    let publisher: String
    let publishedYear: String
    let isbn: String
    let language: String
}

private struct GoogleVolumesResponse: Decodable {
    let items: [GoogleVolume]?
}

private struct GoogleVolume: Decodable {
    let volumeInfo: GoogleVolumeInfo?
}

private struct GoogleVolumeInfo: Decodable {
    let title: String?
    let subtitle: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let industryIdentifiers: [GoogleIndustryIdentifier]?
    let infoLink: String?
    let language: String?
}

private struct GoogleIndustryIdentifier: Decodable {
    let type: String?
    let identifier: String?
}

private struct OpenLibrarySearchResponse: Decodable {
    let docs: [OpenLibraryDoc]?
}

private struct OpenLibraryDoc: Decodable {
    let title: String?
    let subtitle: String?
    let authorName: [String]?
    let firstPublishYear: Int?
    let publisher: [String]?
    let isbn: [String]?
    let language: [String]?
    let key: String?

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case authorName = "author_name"
        case firstPublishYear = "first_publish_year"
        case publisher
        case isbn
        case language
        case key
    }
}
