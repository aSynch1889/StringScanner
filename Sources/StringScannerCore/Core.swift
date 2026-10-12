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

public struct StringLocation: Codable, Hashable {
    public let file: String
    public let line: Int
    public let column: Int
    public let content: String
    public let isLocalized: Bool
    
    public init(file: String, line: Int, column: Int, content: String, isLocalized: Bool) {
        self.file = file
        self.line = line
        self.column = column
        self.content = content
        self.isLocalized = isLocalized
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(file)
        hasher.combine(line)
        hasher.combine(column)
        hasher.combine(content)
        hasher.combine(isLocalized)
    }
    
    public static func == (lhs: StringLocation, rhs: StringLocation) -> Bool {
        return lhs.file == rhs.file &&
               lhs.line == rhs.line &&
               lhs.column == rhs.column &&
               lhs.content == rhs.content &&
               lhs.isLocalized == rhs.isLocalized
    }
}

public class ProjectScanner {
    private let fileManager = FileManager.default
    private let resultsLock = NSLock()
    private let progressLock = NSLock()
    private var allStrings: [StringLocation] = []
    
    public init() {}
    
    @discardableResult
    public func scanProject(
        at path: String,
        configuration: ProjectScanConfiguration = ProjectScanConfiguration()
    ) -> [StringLocation] {
        allStrings = []
        print("Scanning project at: \(path)", to: &stderr)
        
        guard let files = SourceFileFilter.collectFiles(at: path, fileManager: fileManager) else {
            print("Error: Cannot enumerate directory contents", to: &stderr)
            return []
        }
        
        let totalFiles = files.count
        if totalFiles == 0 {
            configuration.onNoScannableFiles?()
            return []
        }
        
        var processedFiles = 0
        
        DispatchQueue.concurrentPerform(iterations: totalFiles) { index in
            let file = files[index]
            do {
                try self.scanFile(at: file)
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
        
        if configuration.emitJSONToStandardOutput {
            outputResults()
        }
        
        return getScanResults()
    }
    
    public func getScanResults() -> [StringLocation] {
        return allStrings.sorted {
            $0.file == $1.file ?
                ($0.line == $1.line ? $0.column < $1.column : $0.line < $1.line) :
                $0.file < $1.file
        }
    }
    
    private func scanFile(at url: URL) throws {
        let source = try String(contentsOf: url, encoding: .utf8)
        let sourceFile = Parser.parse(source: source)
        
        let operatorTable = OperatorTable.standardOperators
        let foldedFile = try operatorTable.foldAll(sourceFile)
        
        let locationConverter = SourceLocationConverter(
            fileName: url.path,
            tree: foldedFile
        )
        
        let visitor = StringVisitor(
            filePath: url.path,
            locationConverter: locationConverter
        )
        
        visitor.walk(foldedFile)
        
        resultsLock.lock()
        allStrings.append(contentsOf: visitor.strings)
        resultsLock.unlock()
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
    public var strings: [StringLocation] = []
    
    public init(filePath: String, locationConverter: SourceLocationConverter) {
        self.filePath = filePath
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }
    
    public override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        let location = node.startLocation(converter: locationConverter)
        let content = node.segments
            .compactMap { $0.as(StringSegmentSyntax.self)?.content.text }
            .joined()
        
        let isLocalized = isInLocalizationContext(node)
        
        strings.append(StringLocation(
            file: filePath,
            line: location.line,
            column: location.column,
            content: content,
            isLocalized: isLocalized
        ))
        
        return .skipChildren
    }
    
    private func isInLocalizationContext(_ node: StringLiteralExprSyntax) -> Bool {
        if let functionCall = node.parent?.as(FunctionCallExprSyntax.self),
           let calledExpression = functionCall.calledExpression.as(DeclReferenceExprSyntax.self),
           calledExpression.baseName.text == "NSLocalizedString" {
            return true
        }
        return false
    }
    
    public override func visit(_ node: RegexLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        let location = node.startLocation(converter: locationConverter)
        strings.append(StringLocation(
            file: filePath,
            line: location.line,
            column: location.column,
            content: node.regex.text,
            isLocalized: false
        ))
        return .skipChildren
    }
}
