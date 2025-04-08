import Foundation
import SwiftUI
import StringScannerCore
import SwiftSyntax
import SwiftParser
import SwiftOperators

class ScannerViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var results: [StringLocation] = []
    @Published var selectedPath: String = ""
    @Published var errorMessage: String?
    
    private let scanner = ProjectScanner()
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "result.queue", attributes: .concurrent)
    private var allStrings: [StringLocation] = []
    
    func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                selectedPath = url.path
            }
        }
    }
    
    func startScan() {
        guard !selectedPath.isEmpty else {
            errorMessage = "Please select a folder first"
            return
        }
        
        isScanning = true
        progress = 0
        results = []
        allStrings = []
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.scanProject(at: self?.selectedPath ?? "")
        }
    }
    
    private func scanProject(at path: String) {
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            DispatchQueue.main.async {
                self.errorMessage = "Cannot enumerate directory contents"
                self.isScanning = false
            }
            return
        }
        
        let files = enumerator.compactMap { $0 as? URL }
            .filter { isValidFile($0) }
        
        let totalFiles = files.count
        var processedFiles = 0
        
        DispatchQueue.concurrentPerform(iterations: files.count) { index in
            let file = files[index]
            do {
                try self.scanFile(at: file)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error scanning \(file.path): \(error)"
                }
            }
            
            processedFiles += 1
            DispatchQueue.main.async {
                self.progress = Double(processedFiles) / Double(totalFiles)
            }
        }
        
        DispatchQueue.main.async {
            self.outputResults()
            self.isScanning = false
        }
    }
    
    private func isValidFile(_ url: URL) -> Bool {
        let validExtensions = ["swift", "m", "h"]
        guard validExtensions.contains(url.pathExtension) else { return false }
        
        let excludedPaths = [
            "/Pods/", "/Carthage/", "/.swiftpm/",
            "/Tests/", "/Test/", "/Specs/",
            "/DerivedData/", "/build/"
        ]
        
        let path = url.path
        return !excludedPaths.contains { path.contains($0) }
    }
    
    private func scanFile(at url: URL) throws {
        let source = try String(contentsOf: url)
        let sourceFile = try Parser.parse(source: source)
        
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
        
        queue.async(flags: .barrier) {
            self.allStrings.append(contentsOf: visitor.strings)
        }
    }
    
    private func outputResults() {
        results = allStrings.sorted {
            $0.file == $1.file ?
                ($0.line == $1.line ? $0.column < $1.column : $0.line < $1.line) :
                $0.file < $1.file
        }
    }
} 