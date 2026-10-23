import AppKit
import CoreText
import PDFKit

// Runs the production MetadataService inside a separately signed sandbox app.
@main
struct MetadataBundleSmoke {
    static func main() {
        do {
            try check(NSHomeDirectory().contains("/Library/Containers/"), "Probe is not sandboxed")
            let fm = FileManager.default
            let workspace = fm.temporaryDirectory.appendingPathComponent("PDF 元数据 test \(UUID().uuidString)")
            try fm.createDirectory(at: workspace, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: workspace) }
            let pdf = workspace.appendingPathComponent("半导体 Power Devices 测试.pdf")
            try makePDF(at: pdf)
            let before = try content(of: pdf)
            try check(before.allSatisfy { $0.contains("Power Devices") }, "Fixture has no readable body text")
            let marker = Data("old-metadata".utf8)
            let xattrResult = marker.withUnsafeBytes { bytes in
                setxattr(pdf.path, "com.pdflibrarian.regression", bytes.baseAddress, marker.count, 0, 0)
            }
            try check(xattrResult == 0, "Could not seed a document xattr")
            let entries = [
                "dc:title": "半导体 Semiconductor Power Devices (Second Edition)",
                "dc:creator": "Josef Lutz, Heinrich Schlangenotto, Uwe Scheuermann, Rik De Doncker",
                "dc:publisher": "Springer International Publishing",
                "dc:date": "2018",
                "dc:language": "en",
                "dc:type": "Text",
                "dc:format": "application/pdf",
                "dc:identifier": "978-3-319-70917-8",
                "dc:subject": "功率器件 Power devices",
                "dc:source": "Regression fixture",
                "dc:relation": "Second Edition",
                "dc:description": "中文 and English metadata round trip"
            ]
            try MetadataService().writeMetadata(fileURL: pdf, entries: entries)
            try check(getxattr(pdf.path, "com.pdflibrarian.regression", nil, 0, 0, 0) == -1 && errno == ENOATTR,
                      "Ordinary document xattr was not cleared")
            try check(try content(of: pdf) == before, "PDF pages or extracted body text changed")
            let metadata = try readEmbeddedMetadata(pdf)
            let tags = ["dc:title": "Title", "dc:creator": "Creator", "dc:publisher": "Publisher",
                        "dc:date": "Date", "dc:language": "Language", "dc:type": "Type",
                        "dc:format": "Format", "dc:identifier": "Identifier", "dc:subject": "Subject",
                        "dc:source": "Source", "dc:relation": "Relation", "dc:description": "Description"]
            for (key, value) in entries {
                let tag = "XMP-dc:\(tags[key]!)"
                let actual = metadata[tag]
                let values = (actual as? [Any] ?? actual.map { [$0] } ?? []).map { String(describing: $0) }
                try check(values.contains(value), "\(tag) not preserved: \(String(describing: actual))")
            }
            let current = try MetadataService().readDublinCoreMetadata(for: pdf)
            for (key, value) in entries {
                try check(current[key] == value, "Current-file reader did not preserve \(key): \(String(describing: current[key]))")
            }
            // A long embedded field exceeds a pipe buffer; reader must drain while running.
            let longDescription = String(repeating: "大字段 Long metadata. ", count: 6000)
            try MetadataService().writeMetadata(fileURL: pdf, key: "dc:description", value: longDescription)
            let longRead = try MetadataService().readDublinCoreMetadata(for: pdf)
            try check(longRead["dc:description"] == longDescription.trimmingCharacters(in: .whitespacesAndNewlines), "Long metadata read truncated or stalled")
            let legacyPDF = workspace.appendingPathComponent("Legacy Info.pdf")
            try makePDF(at: legacyPDF)
            let legacyDocument = PDFDocument(url: legacyPDF)!
            legacyDocument.documentAttributes = [PDFDocumentAttribute.titleAttribute: "Legacy Info title", PDFDocumentAttribute.authorAttribute: "Legacy Author", PDFDocumentAttribute.subjectAttribute: "Legacy subject"]
            try check(legacyDocument.write(to: legacyPDF), "Could not create legacy PDF fixture")
            try check(try readEmbeddedMetadata(legacyPDF)["XMP-dc:Title"] == nil, "Legacy fixture unexpectedly contains XMP")
            let legacyValues = try MetadataService().readDublinCoreMetadata(for: legacyPDF)
            try check(legacyValues["dc:title"] == "Legacy Info title" && legacyValues["dc:creator"] == "Legacy Author" && legacyValues["dc:subject"] == "Legacy subject", "PDF Info fallback did not read actual metadata")
            try check(legacyValues["dc:date"] == nil && legacyValues["dc:format"] == nil, "Missing file metadata was inferred")
            // Exercise repeated writes and the single-field API too.
            try MetadataService().writeMetadata(fileURL: pdf, key: "dc:title", value: "再次写入 Updated title")
            try check(try readEmbeddedMetadata(pdf)["PDF:Title"] as? String == "再次写入 Updated title", "Repeated write failed")
            try check(try content(of: pdf) == before, "Repeated write changed PDF body")
            let invalidPDF = workspace.appendingPathComponent("invalid.pdf")
            let invalidData = Data("not a PDF".utf8)
            try invalidData.write(to: invalidPDF)
            var rejected = false
            do {
                try MetadataService().writeMetadata(fileURL: invalidPDF, key: "dc:title", value: "must fail")
            } catch { rejected = true }
            try check(rejected && (try Data(contentsOf: invalidPDF)) == invalidData, "Failed write changed the original input")
            var readRejected = false
            do { _ = try MetadataService().readDublinCoreMetadata(for: invalidPDF) } catch { readRejected = true }
            try check(readRejected, "Invalid PDF produced fabricated current metadata")
            print("PASS: sandbox, bundled ExifTool, 12 Dublin Core fields, Unicode/spaces, repeated writes, 2 PDF pages/body preserved, failed input untouched, current XMP/PDF Info reads, long-field reads")
        } catch {
            fputs("FAIL: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func check(_ condition: Bool, _ message: String) throws {
        if !condition { throw NSError(domain: "MetadataBundleSmoke", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
    }

    private static func makePDF(at url: URL) throws {
        var bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let context = CGContext(url as CFURL, mediaBox: &bounds, nil)!
        for page in 1...2 {
            context.beginPDFPage(nil)
            let text = NSAttributedString(string: "PDF Librarian regression page \(page): Power Devices", attributes: [
                .font: CTFontCreateWithName("Helvetica" as CFString, 16, nil)
            ])
            context.textPosition = CGPoint(x: 50, y: 700)
            CTLineDraw(CTLineCreateWithAttributedString(text), context)
            context.endPDFPage()
        }
        context.closePDF()
    }

    private static func content(of url: URL) throws -> [String] {
        guard let document = PDFDocument(url: url), document.pageCount == 2 else {
            throw AppError.readFailure(url)
        }
        return (0..<document.pageCount).map { document.page(at: $0)?.string ?? "" }
    }

    private static func readEmbeddedMetadata(_ url: URL) throws -> [String: Any] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [Bundle.main.resourceURL!.appendingPathComponent("ExifTool/bin/exiftool").path,
                             "-config", "", "-j", "-G1", "-XMP-dc:all", "-PDF:Title", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        try check(process.terminationStatus == 0, "Embedded metadata read failed")
        return (try JSONSerialization.jsonObject(with: data) as! [[String: Any]])[0]
    }
}
