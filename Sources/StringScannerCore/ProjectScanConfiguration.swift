import Foundation

public struct ProjectScanConfiguration: Sendable {
    public var emitJSONToStandardOutput: Bool
    public var enableCatalogAudit: Bool
    /// Extra localization wrappers such as `L10n.t` or `tr` (built-ins always included).
    public var localizationFunctions: [LocalizationFunctionSpec]
    public var onProgress: (@Sendable (Double) -> Void)?
    public var onFileError: (@Sendable (String) -> Void)?
    public var onNoScannableFiles: (@Sendable () -> Void)?

    public init(
        emitJSONToStandardOutput: Bool = true,
        enableCatalogAudit: Bool = true,
        localizationFunctions: [LocalizationFunctionSpec] = [],
        onProgress: (@Sendable (Double) -> Void)? = nil,
        onFileError: (@Sendable (String) -> Void)? = nil,
        onNoScannableFiles: (@Sendable () -> Void)? = nil
    ) {
        self.emitJSONToStandardOutput = emitJSONToStandardOutput
        self.enableCatalogAudit = enableCatalogAudit
        self.localizationFunctions = localizationFunctions
        self.onProgress = onProgress
        self.onFileError = onFileError
        self.onNoScannableFiles = onNoScannableFiles
    }

    public var resolvedLocalizationFunctions: [LocalizationFunctionSpec] {
        LocalizationFunctionMatcher.merged(custom: localizationFunctions)
    }

    public static let cliDefault = ProjectScanConfiguration(emitJSONToStandardOutput: false)
    public static let guiDefault = ProjectScanConfiguration(emitJSONToStandardOutput: false)
}
