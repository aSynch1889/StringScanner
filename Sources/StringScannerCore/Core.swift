import Foundation
import SwiftSyntax
import SwiftParser
import SwiftOperators

public struct FileHandleOutputStream: TextOutputStream {
    let fileHandle: FileHandle
    
    public init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }
    
    public mutating func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        fileHandle.write(data)
    }
}

public var stderr = FileHandleOutputStream(fileHandle: .standardError)

public struct StringLocation: Codable, Hashable, Sendable {
    public let file: String
    public let line: Int
    public let column: Int
    public let content: String
    public let isLocalized: Bool
    public let catalogStatus: CatalogKeyStatus
    public let kind: StringKind
    public let isInterpolated: Bool
    public let isConcatenated: Bool

    public init(
        file: String,
        line: Int,
        column: Int,
        content: String,
        isLocalized: Bool,
        catalogStatus: CatalogKeyStatus = .notApplicable,
        kind: StringKind = .copy,
        isInterpolated: Bool = false,
        isConcatenated: Bool = false
    ) {
        self.file = file
        self.line = line
        self.column = column
        self.content = content
        self.isLocalized = isLocalized
        self.catalogStatus = catalogStatus
        self.kind = kind
        self.isInterpolated = isInterpolated
        self.isConcatenated = isConcatenated
    }

    public func withCatalogStatus(_ status: CatalogKeyStatus) -> StringLocation {
        StringLocation(
            file: file,
            line: line,
            column: column,
            content: content,
            isLocalized: isLocalized,
            catalogStatus: status,
            kind: kind,
            isInterpolated: isInterpolated,
            isConcatenated: isConcatenated
        )
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(file)
        hasher.combine(line)
        hasher.combine(column)
        hasher.combine(content)
        hasher.combine(isLocalized)
        hasher.combine(catalogStatus)
        hasher.combine(kind)
        hasher.combine(isInterpolated)
        hasher.combine(isConcatenated)
    }

    public static func == (lhs: StringLocation, rhs: StringLocation) -> Bool {
        lhs.file == rhs.file &&
            lhs.line == rhs.line &&
            lhs.column == rhs.column &&
            lhs.content == rhs.content &&
            lhs.isLocalized == rhs.isLocalized &&
            lhs.catalogStatus == rhs.catalogStatus &&
            lhs.kind == rhs.kind &&
            lhs.isInterpolated == rhs.isInterpolated &&
            lhs.isConcatenated == rhs.isConcatenated
    }
}

public struct ScanReport: Codable, Sendable {
    public let strings: [StringLocation]
    public let catalog: CatalogAudit

    public init(strings: [StringLocation], catalog: CatalogAudit) {
        self.strings = strings
        self.catalog = catalog
    }
}

public class ProjectScanner {
    private let fileManager = FileManager.default
    private let resultsLock = NSLock()
    private let progressLock = NSLock()
    private var allStrings: [StringLocation] = []
    private var lastCatalogAudit: CatalogAudit = .empty

    public init() {}

    public func getCatalogAudit() -> CatalogAudit {
        lastCatalogAudit
    }

    @discardableResult
    public func scanProject(
        at path: String,
        configuration: ProjectScanConfiguration = ProjectScanConfiguration()
    ) -> [StringLocation] {
        scanProjectReport(at: path, configuration: configuration).strings
    }

    @discardableResult
    public func scanProjectReport(
        at path: String,
        configuration: ProjectScanConfiguration = ProjectScanConfiguration()
    ) -> ScanReport {
        allStrings = []
        lastCatalogAudit = .empty
        print("Scanning project at: \(path)", to: &stderr)

        guard let files = SourceFileFilter.collectFiles(at: path, fileManager: fileManager) else {
            print("Error: Cannot enumerate directory contents", to: &stderr)
            return ScanReport(strings: [], catalog: .empty)
        }

        let totalFiles = files.count
        if totalFiles == 0 {
            configuration.onNoScannableFiles?()
            return ScanReport(strings: [], catalog: .empty)
        }

        var processedFiles = 0

        let localizationFunctions = configuration.resolvedLocalizationFunctions

        DispatchQueue.concurrentPerform(iterations: totalFiles) { index in
            let file = files[index]
            do {
                try self.scanFile(at: file, localizationFunctions: localizationFunctions)
            } catch {
                let message = "Error scanning \(file.path): \(error)"
                print(message, to: &stderr)
                configuration.onFileError?(message)
            }

            self.progressLock.lock()
            processedFiles += 1
            let fraction = Double(processedFiles) / Double(totalFiles)
            self.progressLock.unlock()
            configuration.onProgress?(fraction)
        }

        var results = getScanResults()
        let included = configuration.includedStringKinds
        if included != Set(StringKind.allCases) {
            results = results.filter { included.contains($0.kind) }
        }

        if configuration.enableCatalogAudit {
            let catalog = LocalizationCatalogLoader.load(from: path, fileManager: fileManager)
            let referenced = Set(results.filter(\.isLocalized).map(\.content))
            lastCatalogAudit = catalog.audit(againstLocalizedKeys: referenced)
            let missing = Set(lastCatalogAudit.missingFromCatalog)
            results = results.map { location in
                guard location.isLocalized else {
                    return location.withCatalogStatus(.notApplicable)
                }
                return location.withCatalogStatus(missing.contains(location.content) ? .missing : .present)
            }

            print(
                "Catalog audit: \(lastCatalogAudit.keysInCatalog.count) keys, \(lastCatalogAudit.missingFromCatalog.count) missing, \(lastCatalogAudit.unusedInCatalog.count) unused, \(lastCatalogAudit.incompleteLocalizations.count) incomplete",
                to: &stderr
            )
        }

        resultsLock.lock()
        allStrings = results
        resultsLock.unlock()

        if configuration.emitJSONToStandardOutput {
            outputResults()
        }

        return ScanReport(strings: getScanResults(), catalog: lastCatalogAudit)
    }

    public func getScanResults() -> [StringLocation] {
        allStrings.sorted {
            $0.file == $1.file ?
                ($0.line == $1.line ? $0.column < $1.column : $0.line < $1.line) :
                $0.file < $1.file
        }
    }
    
    private func scanFile(
        at url: URL,
        localizationFunctions: [LocalizationFunctionSpec]
    ) throws {
        let source = try String(contentsOf: url, encoding: .utf8)
        let found: [StringLocation]

        switch url.pathExtension.lowercased() {
        case "swift":
            found = try scanSwiftSource(
                source,
                filePath: url.path,
                localizationFunctions: localizationFunctions
            )
        case "m", "h":
            found = ObjCSourceScanner.scan(
                source: source,
                filePath: url.path,
                localizationFunctions: localizationFunctions
            )
        default:
            found = []
        }

        resultsLock.lock()
        allStrings.append(contentsOf: found)
        resultsLock.unlock()
    }

    private func scanSwiftSource(
        _ source: String,
        filePath: String,
        localizationFunctions: [LocalizationFunctionSpec]
    ) throws -> [StringLocation] {
        let sourceFile = Parser.parse(source: source)

        let operatorTable = OperatorTable.standardOperators
        let foldedFile = try operatorTable.foldAll(sourceFile)

        let locationConverter = SourceLocationConverter(
            fileName: filePath,
            tree: foldedFile
        )

        let visitor = StringVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            localizationFunctions: localizationFunctions
        )

        visitor.walk(foldedFile)
        return visitor.strings
    }
    
    private func outputResults() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(getScanResults())
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            print("JSON encoding error: \(error)", to: &stderr)
        }
    }
}

public class StringVisitor: SyntaxVisitor {
    let filePath: String
    let locationConverter: SourceLocationConverter
    let localizationFunctions: [LocalizationFunctionSpec]
    public var strings: [StringLocation] = []

    public init(
        filePath: String,
        locationConverter: SourceLocationConverter,
        localizationFunctions: [LocalizationFunctionSpec] = LocalizationFunctionSpec.builtInDefaults
    ) {
        self.filePath = filePath
        self.locationConverter = locationConverter
        self.localizationFunctions = localizationFunctions
        super.init(viewMode: .sourceAccurate)
    }

    public override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        let location = node.startLocation(converter: locationConverter)
        let rendered = renderLiteral(node)
        let isLocalized = isInLocalizationContext(node)
        let kind = StringKindClassifier.classify(
            content: rendered.content,
            context: StringKindClassifier.context(for: node)
        )

        strings.append(StringLocation(
            file: filePath,
            line: location.line,
            column: location.column,
            content: rendered.content,
            isLocalized: isLocalized,
            kind: kind,
            isInterpolated: rendered.isInterpolated,
            isConcatenated: isInStringConcatenation(node)
        ))

        return .skipChildren
    }

    private func renderLiteral(_ node: StringLiteralExprSyntax) -> (content: String, isInterpolated: Bool) {
        var parts: [String] = []
        var interpolated = false
        for segment in node.segments {
            if let text = segment.as(StringSegmentSyntax.self) {
                parts.append(text.content.text)
            } else if segment.is(ExpressionSegmentSyntax.self) {
                interpolated = true
                parts.append("\\(...)")
            }
        }
        return (parts.joined(), interpolated)
    }

    private func isInStringConcatenation(_ node: StringLiteralExprSyntax) -> Bool {
        var current: Syntax? = Syntax(node).parent
        while let syntax = current {
            if let infix = syntax.as(InfixOperatorExprSyntax.self) {
                if let op = infix.operator.as(BinaryOperatorExprSyntax.self),
                   op.operator.text == "+" {
                    let leftIsString = infix.leftOperand.is(StringLiteralExprSyntax.self)
                        || containsStringLiteral(infix.leftOperand)
                    let rightIsString = infix.rightOperand.is(StringLiteralExprSyntax.self)
                        || containsStringLiteral(infix.rightOperand)
                    if leftIsString && rightIsString {
                        return true
                    }
                }
            }
            current = syntax.parent
        }
        return false
    }

    private func containsStringLiteral(_ expr: ExprSyntax) -> Bool {
        if expr.is(StringLiteralExprSyntax.self) { return true }
        if let infix = expr.as(InfixOperatorExprSyntax.self) {
            return containsStringLiteral(infix.leftOperand) || containsStringLiteral(infix.rightOperand)
        }
        return false
    }

    private func isInLocalizationContext(_ node: StringLiteralExprSyntax) -> Bool {
        var current: Syntax? = Syntax(node).parent
        while let syntax = current {
            if let functionCall = syntax.as(FunctionCallExprSyntax.self),
               containsStringLiteral(node, in: functionCall),
               localizationFunctions.contains(where: { $0.matches(functionCall: functionCall) }) {
                return true
            }
            current = syntax.parent
        }
        return false
    }

    private func containsStringLiteral(
        _ node: StringLiteralExprSyntax,
        in functionCall: FunctionCallExprSyntax
    ) -> Bool {
        functionCall.arguments.contains { argument in
            argument.expression.as(StringLiteralExprSyntax.self)?.position == node.position
        }
    }

    public override func visit(_ node: RegexLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}
