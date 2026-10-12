import Foundation
import StringScannerCore

@main
struct CommandLineTool {
    private struct Options {
        var scanPath: String
        var stdoutOnly: Bool
        var outputFile: URL?
        var fullReport: Bool
        var enableCatalogAudit: Bool
        var localizationFunctions: [LocalizationFunctionSpec]
        var includedStringKinds: Set<StringKind>
    }

    static func main() {
        let options = parseOptions()

        if options.stdoutOnly && options.outputFile != nil {
            print("Error: --stdout cannot be used together with --output", to: &stderr)
            exit(1)
        }

        let startTime = Date()
        let scanner = ProjectScanner()
        let configuration = ProjectScanConfiguration(
            emitJSONToStandardOutput: false,
            enableCatalogAudit: options.enableCatalogAudit,
            localizationFunctions: options.localizationFunctions,
            includedStringKinds: options.includedStringKinds
        )
        let report = scanner.scanProjectReport(at: options.scanPath, configuration: configuration)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let jsonData: Data
            if options.fullReport {
                jsonData = try encoder.encode(report)
            } else {
                jsonData = try encoder.encode(report.strings)
            }

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
        var fullReport = false
        var enableCatalogAudit = true
        var localizationFunctions: [LocalizationFunctionSpec] = []
        var includedStringKinds = StringKind.defaultIncluded

        while !args.isEmpty {
            let arg = args.removeFirst()
            switch arg {
            case "--stdout":
                stdoutOnly = true
            case "--full-report":
                fullReport = true
            case "--no-catalog":
                enableCatalogAudit = false
            case "--localize-func":
                guard let value = args.first else {
                    print("Error: missing value for \(arg)", to: &stderr)
                    exit(1)
                }
                args.removeFirst()
                localizationFunctions.append(contentsOf: LocalizationFunctionMatcher.parseList(value))
            case "--include-kinds":
                guard let value = args.first else {
                    print("Error: missing value for \(arg)", to: &stderr)
                    exit(1)
                }
                args.removeFirst()
                includedStringKinds = StringKind.parseList(value)
                if includedStringKinds.isEmpty {
                    print("Error: no valid kinds in --include-kinds", to: &stderr)
                    exit(1)
                }
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
            outputFile: outputFile,
            fullReport: fullReport,
            enableCatalogAudit: enableCatalogAudit,
            localizationFunctions: localizationFunctions,
            includedStringKinds: includedStringKinds
        )
    }

    private static func printUsage() {
        print("""
        Usage: stringscanner-cli [path] [options]

        Options:
          --stdout          Print JSON to stdout (do not write a file)
          --full-report     Include catalog audit alongside strings
          --no-catalog      Skip .strings / .xcstrings cross-check
          --localize-func   Comma-separated wrappers, e.g. L10n.t,tr
          --include-kinds   copy,format,url,log,sfSymbol,technical or all
                            (default: copy,format)
          -o, --output PATH Write JSON to PATH (default: ./string_scan_results.json)
          -h, --help        Show this help
        """)
    }
}
