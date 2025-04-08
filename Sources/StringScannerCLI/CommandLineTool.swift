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
        print("\nScan completed in \(String(format: "%.2f", elapsedTime)) seconds", to: &stderr)
    }
} 