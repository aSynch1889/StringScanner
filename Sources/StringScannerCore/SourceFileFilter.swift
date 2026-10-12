import Foundation

enum SourceFileFilter {
    private static let validExtensions: Set<String> = ["swift", "m", "h"]

    private static let excludedPathComponents: Set<String> = [
        "Pods", "Carthage", ".swiftpm", "Tests", "Test", "Specs",
        "DerivedData", "build", ".git", ".build", "node_modules"
    ]

    private static let excludedFileNames: Set<String> = [
        "Package.swift", "Package.resolved"
    ]

    static func isValidFile(_ url: URL) -> Bool {
        guard validExtensions.contains(url.pathExtension) else { return false }

        let fileName = url.lastPathComponent
        if excludedFileNames.contains(fileName) { return false }
        if fileName.hasSuffix(".generated.swift") { return false }

        let components = url.pathComponents
        if components.contains(where: { excludedPathComponents.contains($0) }) {
            return false
        }

        return true
    }

    static func collectFiles(at path: String, fileManager: FileManager = .default) -> [URL]? {
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return nil
        }

        return enumerator.compactMap { $0 as? URL }.filter { isValidFile($0) }
    }
}
