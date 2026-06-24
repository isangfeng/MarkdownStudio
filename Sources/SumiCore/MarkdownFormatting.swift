import Foundation

public enum MarkdownFormatStyle: Equatable {
    case bold
    case italic
    case inlineCode
    case heading(Int)
    case paragraph
    case bulletList
    case numberedList
    case blockquote
    case codeBlock
    case link
    case image
    case table
    case horizontalRule
}

public struct MarkdownFormatResult: Equatable {
    public var text: String
    public var selection: NSRange
}

public enum MarkdownFormatting {
    public static func apply(style: MarkdownFormatStyle, to text: String, selection: NSRange) -> MarkdownFormatResult {
        switch style {
        case .bold:
            wrap(text, selection: selection, prefix: "**", suffix: "**", placeholder: "strong text")
        case .italic:
            wrap(text, selection: selection, prefix: "*", suffix: "*", placeholder: "emphasized text")
        case .inlineCode:
            wrap(text, selection: selection, prefix: "`", suffix: "`", placeholder: "code")
        case .heading(let level):
            applyLinePrefix(text, selection: selection, prefix: String(repeating: "#", count: max(1, min(level, 6))) + " ")
        case .paragraph:
            applyLinePrefix(text, selection: selection, prefix: "")
        case .bulletList:
            applyLinePrefix(text, selection: selection, prefix: "- ")
        case .numberedList:
            applyNumberedList(text, selection: selection)
        case .blockquote:
            applyLinePrefix(text, selection: selection, prefix: "> ")
        case .codeBlock:
            wrap(text, selection: selection, prefix: "```\n", suffix: "\n```", placeholder: "code")
        case .link:
            wrap(text, selection: selection, prefix: "[", suffix: "](https://)", placeholder: "link text")
        case .image:
            wrap(text, selection: selection, prefix: "![", suffix: "](https://)", placeholder: "alt text")
        case .table:
            insertTable(text, selection: selection)
        case .horizontalRule:
            insertHorizontalRule(text, selection: selection)
        }
    }

    private static func insertTable(_ text: String, selection: NSRange) -> MarkdownFormatResult {
        let template = "| Header | Header |\n| --- | --- |\n| Cell | Cell |"
        let storage = NSMutableString(string: text)
        storage.replaceCharacters(in: selection, with: template)

        let headerLocation = selection.location + 2
        return MarkdownFormatResult(
            text: storage as String,
            selection: NSRange(location: headerLocation, length: 6)
        )
    }

    private static func insertHorizontalRule(_ text: String, selection: NSRange) -> MarkdownFormatResult {
        let insertion = "\n\n---\n\n"
        let storage = NSMutableString(string: text)
        storage.replaceCharacters(in: selection, with: insertion)

        let cursor = selection.location + (insertion as NSString).length
        return MarkdownFormatResult(
            text: storage as String,
            selection: NSRange(location: cursor, length: 0)
        )
    }

    private static func wrap(
        _ text: String,
        selection: NSRange,
        prefix: String,
        suffix: String,
        placeholder: String
    ) -> MarkdownFormatResult {
        let storage = NSMutableString(string: text)
        let selected = selection.length == 0 ? placeholder : storage.substring(with: selection)
        let replacement = prefix + selected + suffix
        storage.replaceCharacters(in: selection, with: replacement)

        let selectedLocation = selection.location + (prefix as NSString).length
        let selectedLength = (selected as NSString).length
        return MarkdownFormatResult(
            text: storage as String,
            selection: NSRange(location: selectedLocation, length: selectedLength)
        )
    }

    private static func applyLinePrefix(_ text: String, selection: NSRange, prefix: String) -> MarkdownFormatResult {
        let nsText = text as NSString
        let range = expandedLineRange(in: nsText, around: selection)
        let original = nsText.substring(with: range)
        let lines = original.components(separatedBy: "\n")
        let transformed = lines.enumerated().map { index, line in
            if index == lines.count - 1 && line.isEmpty {
                return line
            }
            return prefix + strippedBlockPrefix(from: line)
        }.joined(separator: "\n")

        let storage = NSMutableString(string: text)
        storage.replaceCharacters(in: range, with: transformed)
        return MarkdownFormatResult(
            text: storage as String,
            selection: NSRange(location: range.location, length: (transformed as NSString).length)
        )
    }

    private static func applyNumberedList(_ text: String, selection: NSRange) -> MarkdownFormatResult {
        let nsText = text as NSString
        let range = expandedLineRange(in: nsText, around: selection)
        let original = nsText.substring(with: range)
        var number = 1
        let lines = original.components(separatedBy: "\n")
        let transformed = lines.enumerated().map { index, line in
            if index == lines.count - 1 && line.isEmpty {
                return line
            }
            defer { number += 1 }
            return "\(number). " + strippedBlockPrefix(from: line)
        }.joined(separator: "\n")

        let storage = NSMutableString(string: text)
        storage.replaceCharacters(in: range, with: transformed)
        return MarkdownFormatResult(
            text: storage as String,
            selection: NSRange(location: range.location, length: (transformed as NSString).length)
        )
    }

    private static func expandedLineRange(in text: NSString, around selection: NSRange) -> NSRange {
        let length = text.length
        let startRange = text.lineRange(for: NSRange(location: min(selection.location, length), length: 0))
        let selectionEnd = min(selection.location + max(selection.length - 1, 0), max(length - 1, 0))
        let endRange = text.lineRange(for: NSRange(location: max(selectionEnd, 0), length: 0))
        let start = startRange.location
        let end = max(startRange.location + startRange.length, endRange.location + endRange.length)
        return NSRange(location: start, length: end - start)
    }

    private static func strippedBlockPrefix(from line: String) -> String {
        let patterns = [
            #"^\s{0,3}#{1,6}\s+"#,
            #"^\s{0,3}[-*+]\s+"#,
            #"^\s{0,3}\d+\.\s+"#,
            #"^\s{0,3}>\s?"#
        ]

        var result = line
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: result, range: NSRange(location: 0, length: (result as NSString).length)),
               match.range.location == 0 {
                result = (result as NSString).replacingCharacters(in: match.range, with: "")
                break
            }
        }
        return result
    }
}
