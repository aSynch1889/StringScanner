import Foundation
import SwiftUI
import StringScannerCore

class ScannerViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var results: [StringLocation] = []
    @Published var catalogAudit: CatalogAudit = .empty
    @Published var selectedPath: String = ""
    @Published var errorMessage: String?
    @Published private(set) var scanFailureCount = 0

    private let scanner = ProjectScanner()

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
            errorMessage = L10n.t(.selectFolderFirst)
            return
        }

        isScanning = true
        progress = 0
        results = []
        catalogAudit = .empty
        errorMessage = nil
        scanFailureCount = 0

        let path = selectedPath
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let configuration = ProjectScanConfiguration(
                emitJSONToStandardOutput: false,
                onProgress: { fraction in
                    DispatchQueue.main.async {
                        self.progress = fraction
                    }
                },
                onFileError: { message in
                    DispatchQueue.main.async {
                        self.scanFailureCount += 1
                        if self.scanFailureCount == 1 {
                            self.errorMessage = message
                        } else {
                            self.errorMessage = L10n.format(
                                .filesFailedScan,
                                self.scanFailureCount,
                                message
                            )
                        }
                    }
                },
                onNoScannableFiles: {
                    DispatchQueue.main.async {
                        self.errorMessage = L10n.t(.noScannableFiles)
                        self.progress = 0
                    }
                }
            )

            let report = self.scanner.scanProjectReport(at: path, configuration: configuration)

            DispatchQueue.main.async {
                self.results = report.strings
                self.catalogAudit = report.catalog
                self.isScanning = false
            }
        }
    }

    func exportToJSON() {
        guard !results.isEmpty else {
            errorMessage = L10n.t(.noResultsToExport)
            return
        }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "strings.json"
        savePanel.allowedContentTypes = [.json]

        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }

            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(results)
                try data.write(to: url)
            } catch {
                errorMessage = L10n.format(.failedExportJSON, error.localizedDescription)
            }
        }
    }

    func exportToCSV() {
        guard !results.isEmpty else {
            errorMessage = L10n.t(.noResultsToExport)
            return
        }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "strings.csv"
        savePanel.allowedContentTypes = [.commaSeparatedText]

        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }

            do {
                var csvString = "String,File,Line,Column,Is Localized\n"

                for result in results {
                    let escapedContent = result.content.replacingOccurrences(of: "\"", with: "\"\"")
                    let escapedFile = result.file.replacingOccurrences(of: "\"", with: "\"\"")

                    csvString += "\"\(escapedContent)\",\"\(escapedFile)\",\(result.line),\(result.column),\"\(result.isLocalized ? "Yes" : "No")\"\n"
                }

                try csvString.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                errorMessage = L10n.format(.failedExportCSV, error.localizedDescription)
            }
        }
    }
}
