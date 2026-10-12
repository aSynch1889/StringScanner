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
        var xcstringsOutput: URL?
        var stringsOutput: URL?
        var localizationExportScope: LocalizationExportScope
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
            } else if options.xcstringsOutput == nil && options.stringsOutput == nil {
                let destination = options.outputFile
                    ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("string_scan_results.json")
                try jsonData.write(to: destination)
                print("Results saved to: \(destination.path)", to: &stderr)
            } else if let jsonOut = options.outputFile {
                try jsonData.write(to: jsonOut)
                print("Results saved to: \(jsonOut.path)", to: &stderr)
            }
        } catch {
            print("Error writing results: \(error)", to: &stderr)
            exit(1)
        }

        do {
            if let xcURL = options.xcstringsOutput {
                let data = try LocalizationFileExporter.makeXCStringsData(
                    from: report.strings,
                    scope: options.localizationExportScope
                )
                try data.write(to: xcURL, options: .atomic)
                print("String Catalog saved to: \(xcURL.path)", to: &stderr)
            }
            if let stringsURL = options.stringsOutput {
                let body = LocalizationFileExporter.makeStringsFile(
                    from: report.strings,
                    scope: options.localizationExportScope
                )
                try body.write(to: stringsURL, atomically: true, encoding: .utf8)
                print("Strings file saved to: \(stringsURL.path)", to: &stderr)
            }
        } catch {
            print("Error writing localization export: \(error)", to: &stderr)
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
        var xcstringsOutput: URL?
        var stringsOutput: URL?
        var localizationExportScope: LocalizationExportScope = .unlocalizedOnly

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
            case "--export-xcstrings":
                guard let path = args.first else {
                    print("Error: missing value for \(arg)", to: &stderr)
                    exit(1)
                }
                args.removeFirst()
                xcstringsOutput = URL(fileURLWithPath: path)
            case "--export-strings":
                guard let path = args.first else {
                    print("Error: missing value for \(arg)", to: &stderr)
                    exit(1)
                }
                args.removeFirst()
                stringsOutput = URL(fileURLWithPath: path)
            case "--export-scope":
                guard let value = args.first else {
                    print("Error: missing value for \(arg)", to: &stderr)
                    exit(1)
                }
                args.removeFirst()
                guard let scope = LocalizationExportScope(rawValue: value) else {
                    print("Error: invalid --export-scope \(value)", to: &stderr)
                    exit(1)
                }
                localizationExportScope = scope
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
            includedStringKinds: includedStringKinds,
            xcstringsOutput: xcstringsOutput,
            stringsOutput: stringsOutput,
            localizationExportScope: localizationExportScope
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
          --export-xcstrings PATH  Write Xcode String Catalog (.xcstrings)
          --export-strings PATH    Write Localizable.strings
          --export-scope SCOPE     unlocalizedOnly | all | localizedOnly
                                   (default: unlocalizedOnly)
          -o, --output PATH Write JSON to PATH (default: ./string_scan_results.json
                            unless only localization exports are requested)
          -h, --help        Show this help
        """)
    }
}
