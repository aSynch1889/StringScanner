import Foundation
import StringScannerCore

@main
struct CommandLineTool {
    private struct Options {
        var scanPath: String
        var stdoutOnly: Bool
        var outputFile: URL?
    }

    static func main() {
        let options = parseOptions()

        if options.stdoutOnly && options.outputFile != nil {
            print("Error: --stdout cannot be used together with --output", to: &stderr)
            exit(1)
        }

        let startTime = Date()
        let scanner = ProjectScanner()

        let results = scanner.scanProject(at: options.scanPath, configuration: .cliDefault)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let jsonData = try encoder.encode(results)

            if options.stdoutOnly {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            } else {
                let destination = options.outputFile
                    ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("string_scan_results.json")
                try jsonData.write(to: destination)
                print("Results saved to: \(destination.path)", to: &stderr)
            }
        } catch {
            print("Error writing results: \(error)", to: &stderr)
            exit(1)
        }

        let elapsedTime = Date().timeIntervalSince(startTime)
        print(
            String(format: "Scan completed in %.2f seconds", elapsedTime),
            to: &stderr
        )
    }

    private static func parseOptions() -> Options {
        var args = Array(CommandLine.arguments.dropFirst())
        var scanPath: String?
        var stdoutOnly = false
        var outputFile: URL?

        while !args.isEmpty {
            let arg = args.removeFirst()
            switch arg {
            case "--stdout":
                stdoutOnly = true
            case "--output", "-o":
                guard let path = args.first else {
                    print("Error: missing value for \(arg)", to: &stderr)
                    exit(1)
                }
                args.removeFirst()
                outputFile = URL(fileURLWithPath: path)
            case "--help", "-h":
                printUsage()
                exit(0)
            default:
                if scanPath == nil {
                    scanPath = arg
                } else {
                    print("Error: unexpected argument \(arg)", to: &stderr)
                    exit(1)
                }
            }
        }

        return Options(
            scanPath: scanPath ?? FileManager.default.currentDirectoryPath,
            stdoutOnly: stdoutOnly,
            outputFile: outputFile
        )
    }

    private static func printUsage() {
        print("""
        Usage: stringscanner-cli [path] [options]

        Options:
          --stdout          Print JSON to stdout (do not write a file)
          -o, --output PATH Write JSON to PATH (default: ./string_scan_results.json)
          -h, --help        Show this help
        """)
    }
}
