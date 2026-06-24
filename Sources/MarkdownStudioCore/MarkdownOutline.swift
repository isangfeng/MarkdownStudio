import Foundation

public struct MarkdownOutlineItem: Equatable, Identifiable {
    public var id: Int { lineNumber }
    public let level: Int
    public let title: String
    public let lineNumber: Int

    public init(level: Int, title: String, lineNumber: Int) {
        self.level = level
        self.title = title
        self.lineNumber = lineNumber
    }
}

public enum MarkdownOutline {
    public static func parse(_ text: String) -> [MarkdownOutlineItem] {
        var items: [MarkdownOutlineItem] = []
        var isInFencedCodeBlock = false

        for (index, line) in text.components(separatedBy: .newlines).enumerated() {
            let trimmedLeading = line.trimmingCharacters(in: .whitespaces)

            if trimmedLeading.hasPrefix("```") || trimmedLeading.hasPrefix("~~~") {
                isInFencedCodeBlock.toggle()
                continue
            }

            guard !isInFencedCodeBlock,
                  let heading = parseHeading(from: line, lineNumber: index + 1) else {
                continue
            }

            items.append(heading)
        }

        return items
    }

    private static func parseHeading(from line: String, lineNumber: Int) -> MarkdownOutlineItem? {
        let pattern = #"^\s{0,3}(#{1,6})\s+(.+?)(?:\s+#+)?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)),
              match.numberOfRanges == 3 else {
            return nil
        }

        let nsLine = line as NSString
        let marker = nsLine.substring(with: match.range(at: 1))
        let title = nsLine.substring(with: match.range(at: 2))
            .trimmingCharacters(in: .whitespaces)

        guard !title.isEmpty else {
            return nil
        }

        return MarkdownOutlineItem(level: marker.count, title: title, lineNumber: lineNumber)
    }
}
