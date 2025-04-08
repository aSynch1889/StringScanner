import Foundation
import StringScannerCore

@main
struct CommandLineTool {
    static func main() {
        let startTime = Date()
        let scanner = ProjectScanner()
        
        let path = CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath
        scanner.scanProject(at: path)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        // print("\nScan completed in \(String(format: "%.2f", elapsedTime)) seconds", to: &stderr)
        
        // Save results to JSON file
        let outputFile = URL(fileURLWithPath: path).appendingPathComponent("string_scan_results.json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(scanner.getScanResults())
            try jsonData.write(to: outputFile)
            print("Results saved to: \(outputFile.path)", to: &stderr)
        } catch {
            print("Error saving results to file: \(error)", to: &stderr)
        }
    }
} 
