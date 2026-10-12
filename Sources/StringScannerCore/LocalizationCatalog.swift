import Foundation

public enum CatalogKeyStatus: String, Codable, Sendable, Hashable {
    case present
    case missing
    case notApplicable
}

public struct IncompleteLocalization: Codable, Sendable, Hashable {
    public let key: String
    public let missingLocales: [String]

    public init(key: String, missingLocales: [String]) {
        self.key = key
        self.missingLocales = missingLocales
    }
}

public struct CatalogAudit: Codable, Sendable, Hashable {
    public let catalogFiles: [String]
    public let locales: [String]
    public let keysInCatalog: [String]
    public let missingFromCatalog: [String]
    public let unusedInCatalog: [String]
    public let incompleteLocalizations: [IncompleteLocalization]

    public init(
        catalogFiles: [String],
        locales: [String],
        keysInCatalog: [String],
        missingFromCatalog: [String],
        unusedInCatalog: [String],
        incompleteLocalizations: [IncompleteLocalization]
    ) {
        self.catalogFiles = catalogFiles
        self.locales = locales
        self.keysInCatalog = keysInCatalog
        self.missingFromCatalog = missingFromCatalog
        self.unusedInCatalog = unusedInCatalog
        self.incompleteLocalizations = incompleteLocalizations
    }

    public static let empty = CatalogAudit(
        catalogFiles: [],
        locales: [],
        keysInCatalog: [],
        missingFromCatalog: [],
        unusedInCatalog: [],
        incompleteLocalizations: []
    )
}

struct LocalizationCatalog {
    var files: [String] = []
    var locales: Set<String> = []
    /// key -> locales that define a value
    var keyLocales: [String: Set<String>] = [:]

    var keys: Set<String> { Set(keyLocales.keys) }

    mutating func add(key: String, locale: String, file: String) {
        if !files.contains(file) {
            files.append(file)
        }
        locales.insert(locale)
        keyLocales[key, default: []].insert(locale)
    }

    func audit(againstLocalizedKeys referencedKeys: Set<String>) -> CatalogAudit {
        let catalogKeys = keys
        let missing = referencedKeys.subtracting(catalogKeys).sorted()
        let unused = catalogKeys.subtracting(referencedKeys).sorted()
        let allLocales = locales.sorted()

        let incomplete: [IncompleteLocalization] = catalogKeys.sorted().compactMap { key in
            let present = keyLocales[key] ?? []
            let absent = allLocales.filter { !present.contains($0) }
            guard !absent.isEmpty, !allLocales.isEmpty else { return nil }
            // Only flag when at least one locale exists but not all
            guard present.count < allLocales.count else { return nil }
            return IncompleteLocalization(key: key, missingLocales: absent)
        }

        return CatalogAudit(
            catalogFiles: files.sorted(),
            locales: allLocales,
            keysInCatalog: catalogKeys.sorted(),
            missingFromCatalog: missing,
            unusedInCatalog: unused,
            incompleteLocalizations: incomplete
        )
    }
}

enum LocalizationCatalogLoader {
    static func load(from root: String, fileManager: FileManager = .default) -> LocalizationCatalog {
        var catalog = LocalizationCatalog()
        let rootURL = URL(fileURLWithPath: root)

        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return catalog
        }

        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            let pathComponents = url.pathComponents
            if pathComponents.contains(where: {
                ["Pods", "Carthage", ".swiftpm", "DerivedData", "build", ".git", ".build", "node_modules"]
                    .contains($0)
            }) {
                continue
            }

            switch ext {
            case "strings":
                loadStringsFile(at: url, into: &catalog)
            case "xcstrings":
                loadXCStringsFile(at: url, into: &catalog)
            default:
                continue
            }
        }

        return catalog
    }

    private static func loadStringsFile(at url: URL, into catalog: inout LocalizationCatalog) {
        guard let source = try? String(contentsOf: url, encoding: .utf8) else { return }
        let locale = localeFromStringsPath(url)
        let pattern = #"^\s*"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return
        }

        let nsSource = source as NSString
        let fullRange = NSRange(location: 0, length: nsSource.length)
        regex.enumerateMatches(in: source, range: fullRange) { match, _, _ in
            guard let match, match.numberOfRanges > 1 else { return }
            let key = unescape(nsSource.substring(with: match.range(at: 1)))
            catalog.add(key: key, locale: locale, file: url.path)
        }
    }

    private static func loadXCStringsFile(at url: URL, into catalog: inout LocalizationCatalog) {
        guard
            let data = try? Data(contentsOf: url),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let strings = root["strings"] as? [String: Any]
        else {
            return
        }

        let sourceLanguage = (root["sourceLanguage"] as? String) ?? "en"

        for (key, value) in strings {
            guard let entry = value as? [String: Any] else {
                catalog.add(key: key, locale: sourceLanguage, file: url.path)
                continue
            }

            if let localizations = entry["localizations"] as? [String: Any], !localizations.isEmpty {
                for (locale, localizationValue) in localizations {
                    if localizationHasValue(localizationValue) {
                        catalog.add(key: key, locale: locale, file: url.path)
                    }
                }
            } else {
                // Key declared without per-locale values still counts for source language.
                catalog.add(key: key, locale: sourceLanguage, file: url.path)
            }
        }
    }

    private static func localizationHasValue(_ value: Any) -> Bool {
        guard let dict = value as? [String: Any] else { return false }
        if let unit = dict["stringUnit"] as? [String: Any], unit["value"] != nil {
            return true
        }
        if let variations = dict["variations"] as? [String: Any], !variations.isEmpty {
            return true
        }
        return false
    }

    private static func localeFromStringsPath(_ url: URL) -> String {
        // .../zh-Hans.lproj/Localizable.strings
        for component in url.pathComponents where component.hasSuffix(".lproj") {
            return String(component.dropLast(".lproj".count))
        }
        return "Base"
    }

    private static func unescape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
