import Foundation

public struct ProjectScanConfiguration: Sendable {
    public var emitJSONToStandardOutput: Bool
    public var enableCatalogAudit: Bool
    public var onProgress: (@Sendable (Double) -> Void)?
    public var onFileError: (@Sendable (String) -> Void)?
    public var onNoScannableFiles: (@Sendable () -> Void)?

    public init(
        emitJSONToStandardOutput: Bool = true,
        enableCatalogAudit: Bool = true,
        onProgress: (@Sendable (Double) -> Void)? = nil,
        onFileError: (@Sendable (String) -> Void)? = nil,
        onNoScannableFiles: (@Sendable () -> Void)? = nil
    ) {
        self.emitJSONToStandardOutput = emitJSONToStandardOutput
        self.enableCatalogAudit = enableCatalogAudit
        self.onProgress = onProgress
        self.onFileError = onFileError
        self.onNoScannableFiles = onNoScannableFiles
    }

    public static let cliDefault = ProjectScanConfiguration(emitJSONToStandardOutput: false)
    public static let guiDefault = ProjectScanConfiguration(emitJSONToStandardOutput: false)
}
