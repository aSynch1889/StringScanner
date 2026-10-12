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

    func testDetectsSwiftLocalizationAPIs() throws {
        try copyFixture("localization_sample.swift", into: tempRoot)

        let scanner = ProjectScanner()
        let results = scanner.scanProject(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(emitJSONToStandardOutput: false)
        )

        XCTAssertTrue(results.contains { $0.content == "key_ns" && $0.isLocalized })
        XCTAssertTrue(results.contains { $0.content == "key_string_localized" && $0.isLocalized })
        XCTAssertTrue(results.contains { $0.content == "key_text" && $0.isLocalized })
        XCTAssertTrue(results.contains { $0.content == "key_lsk" && $0.isLocalized })
        XCTAssertTrue(results.contains { $0.content == "plain_string" && !$0.isLocalized })
    }

    func testScansObjectiveCStringLiterals() throws {
        try copyFixture("sample.m", into: tempRoot)

        let scanner = ProjectScanner()
        let results = scanner.scanProject(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(emitJSONToStandardOutput: false)
        )

        XCTAssertTrue(results.contains { $0.content == "objc_plain" && !$0.isLocalized })
        XCTAssertTrue(results.contains { $0.content == "objc_localized" && $0.isLocalized })
    }

    func testClassifiesAndFiltersNonCopyKindsByDefault() throws {
        try copyFixture("kind_sample.swift", into: tempRoot)

        let scanner = ProjectScanner()
        let filtered = scanner.scanProject(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(
                emitJSONToStandardOutput: false,
                enableCatalogAudit: false
            )
        )
        XCTAssertTrue(filtered.contains { $0.content == "Welcome back" && $0.kind == .copy })
        XCTAssertTrue(filtered.contains { $0.content == "Hello, %@" && $0.kind == .format })
        XCTAssertFalse(filtered.contains { $0.content == "https://example.com/api" })
        XCTAssertFalse(filtered.contains { $0.content == "debug dump" })
        XCTAssertFalse(filtered.contains { $0.content == "chevron.right" })

        let all = scanner.scanProject(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(
                emitJSONToStandardOutput: false,
                enableCatalogAudit: false,
                includedStringKinds: Set(StringKind.allCases)
            )
        )
        XCTAssertTrue(all.contains { $0.content == "https://example.com/api" && $0.kind == .url })
        XCTAssertTrue(all.contains { $0.content == "debug dump" && $0.kind == .log })
        XCTAssertTrue(all.contains { $0.content == "chevron.right" && $0.kind == .sfSymbol })
        XCTAssertTrue(all.contains { $0.content == "com.example.app.module" && $0.kind == .technical })
    }

    func testCustomLocalizationWrappersAreDetected() throws {
        try copyFixture("custom_localize.swift", into: tempRoot)

        let scanner = ProjectScanner()
        let results = scanner.scanProject(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(
                emitJSONToStandardOutput: false,
                enableCatalogAudit: false,
                localizationFunctions: [
                    LocalizationFunctionSpec(pattern: "L10n.t"),
                    LocalizationFunctionSpec(pattern: "tr")
                ]
            )
        )

        XCTAssertTrue(results.contains { $0.content == "custom_key" && $0.isLocalized })
        XCTAssertTrue(results.contains { $0.content == "tr_key" && $0.isLocalized })
        XCTAssertTrue(results.contains { $0.content == "still_plain" && !$0.isLocalized })
    }

    func testCatalogAuditMarksMissingAndUnusedKeys() throws {
        try copyFixture("localization_sample.swift", into: tempRoot)
        let en = tempRoot.appendingPathComponent("en.lproj", isDirectory: true)
        let zh = tempRoot.appendingPathComponent("zh-Hans.lproj", isDirectory: true)
        try FileManager.default.createDirectory(at: en, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: zh, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: fixturesURL(named: "en.lproj/Localizable.strings"),
            to: en.appendingPathComponent("Localizable.strings")
        )
        try FileManager.default.copyItem(
            at: fixturesURL(named: "zh-Hans.lproj/Localizable.strings"),
            to: zh.appendingPathComponent("Localizable.strings")
        )
        try FileManager.default.copyItem(
            at: fixturesURL(named: "Localizable.xcstrings"),
            to: tempRoot.appendingPathComponent("Localizable.xcstrings")
        )

        let scanner = ProjectScanner()
        let report = scanner.scanProjectReport(
            at: tempRoot.path,
            configuration: ProjectScanConfiguration(emitJSONToStandardOutput: false)
        )

        XCTAssertTrue(report.strings.contains {
            $0.content == "key_ns" && $0.isLocalized && $0.catalogStatus == .present
        })
        XCTAssertTrue(report.strings.contains {
            $0.content == "key_lsk" && $0.isLocalized && $0.catalogStatus == .missing
        })
        XCTAssertTrue(report.catalog.unusedInCatalog.contains("orphan_key"))
        XCTAssertTrue(report.catalog.unusedInCatalog.contains("xc_only"))
        XCTAssertTrue(report.catalog.missingFromCatalog.contains("key_lsk"))
        XCTAssertFalse(report.catalog.incompleteLocalizations.isEmpty)
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
