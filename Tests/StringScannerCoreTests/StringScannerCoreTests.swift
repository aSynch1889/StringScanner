import XCTest
@testable import StringScannerCore

final class StringScannerCoreTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("StringScannerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    private func fixturesURL(named name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name)")
    }

    private func copyFixture(_ name: String, into directory: URL) throws {
        let source = fixturesURL(named: name)
        try FileManager.default.copyItem(at: source, to: directory.appendingPathComponent(name))
    }

    func testFindsStringLiteralInSwiftSource() throws {
        try copyFixture("simple.swift", into: tempRoot)

        let scanner = ProjectScanner()
        let results = scanner.scanProject(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(emitJSONToStandardOutput: false)
        )

        XCTAssertTrue(results.contains { $0.content == "Hello" && !$0.isLocalized })
    }

    func testSkipsPackageManifestByDefault() throws {
        try copyFixture("simple.swift", into: tempRoot)
        let packageManifest = """
        let package = "ShouldNotAppear"
        """
        try packageManifest.write(
            to: tempRoot.appendingPathComponent("Package.swift"),
            atomically: true,
            encoding: .utf8
        )

        let scanner = ProjectScanner()
        let results = scanner.scanProject(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(emitJSONToStandardOutput: false)
        )

        XCTAssertFalse(results.contains { $0.content == "ShouldNotAppear" })
        XCTAssertTrue(results.contains { $0.content == "Hello" })
    }

    func testResultsAreSortedByFileThenLine() throws {
        let sources = tempRoot.appendingPathComponent("Sources", isDirectory: true)
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try copyFixture("simple.swift", into: sources)

        let scanner = ProjectScanner()
        let results = scanner.scanProject(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(emitJSONToStandardOutput: false)
        )

        let sortedAgain = results.sorted {
            $0.file == $1.file ?
                ($0.line == $1.line ? $0.column < $1.column : $0.line < $1.line) :
                $0.file < $1.file
        }
        XCTAssertEqual(results, sortedAgain)
    }
}
