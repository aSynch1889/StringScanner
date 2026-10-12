import Foundation

enum ObjCSourceScanner {
    private static let stringLiteralPattern = #"@"((?:\\.|[^"\\])*)""#

    static func scan(source: String, filePath: String) -> [StringLocation] {
        guard let regex = try? NSRegularExpression(pattern: stringLiteralPattern) else {
            return []
        }

        let nsSource = source as NSString
        let fullRange = NSRange(location: 0, length: nsSource.length)
        var results: [StringLocation] = []

        regex.enumerateMatches(in: source, range: fullRange) { match, _, _ in
            guard let match, match.numberOfRanges > 1 else { return }

            let contentRange = match.range(at: 1)
            let fullMatchRange = match.range(at: 0)
            let rawContent = nsSource.substring(with: contentRange)
            let content = unescapeObjCString(rawContent)

            let prefix = nsSource.substring(with: NSRange(location: 0, length: fullMatchRange.location))
            let line = prefix.filter { $0 == "\n" }.count + 1
            let column: Int
            if let lastNewline = prefix.lastIndex(of: "\n") {
                column = prefix.distance(from: lastNewline, to: prefix.endIndex)
            } else {
                column = fullMatchRange.location
            }

            let localizedContext = nsSource.substring(
                with: NSRange(location: max(0, fullMatchRange.location - 80), length: min(80, fullMatchRange.location))
            )
            let isLocalized = localizedContext.contains("NSLocalizedString")

            results.append(StringLocation(
                file: filePath,
                line: line,
                column: column + 1,
                content: content,
                isLocalized: isLocalized
            ))
        }

        return results
    }

    private static func unescapeObjCString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
