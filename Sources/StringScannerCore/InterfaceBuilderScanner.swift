import Foundation

enum InterfaceBuilderScanner {
    private static let attributeNames = [
        "text", "title", "placeholder", "headerTitle", "label",
        "accessibilityLabel", "accessibilityHint", "normalTitle",
        "highlightedTitle", "selectedTitle", "disabledTitle"
    ]

    static func scan(source: String, filePath: String) -> [StringLocation] {
        var results: [StringLocation] = []
        for name in attributeNames {
            let pattern = #"\#(name)\s*=\s*"((?:\\.|[^"\\])*)""#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let nsSource = source as NSString
            let fullRange = NSRange(location: 0, length: nsSource.length)
            regex.enumerateMatches(in: source, range: fullRange) { match, _, _ in
                guard let match, match.numberOfRanges > 1 else { return }
                let content = unescape(nsSource.substring(with: match.range(at: 1)))
                guard !content.isEmpty else { return }
                // Skip Interface Builder runtime placeholders
                if content.hasPrefix("$") { return }

                let prefix = nsSource.substring(with: NSRange(location: 0, length: match.range.location))
                let line = prefix.filter { $0 == "\n" }.count + 1
                let column: Int
                if let lastNewline = prefix.lastIndex(of: "\n") {
                    column = prefix.distance(from: lastNewline, to: prefix.endIndex) + 1
                } else {
                    column = match.range.location + 1
                }

                results.append(StringLocation(
                    file: filePath,
                    line: line,
                    column: column,
                    content: content,
                    isLocalized: false,
                    kind: .copy,
                    origin: .interfaceBuilder
                ))
            }
        }
        return results
    }

    private static func unescape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "\\\"", with: "\"")
    }
}
