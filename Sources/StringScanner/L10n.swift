import Foundation

enum L10nKey {
    case brandSubtitle
    case target
    case chooseFolder
    case changeFolder
    case startScan
    case scanning
    case session
    case found
    case localized
    case pickHint
    case notice
    case ok
    case noScanYet
    case emptyHint
    case scanningProject
    case noMatches
    case noMatchesHint
    case filterPlaceholder
    case filterAll
    case filterLocalized
    case filterPlain
    case exportJSON
    case exportCSV
    case exportMenu
    case exportXCStrings
    case exportStrings
    case failedExportXCStrings
    case failedExportStrings
    case stringsCount
    case localizedBadge
    case catalogMissingBadge
    case localizeFunctions
    case localizeFunctionsHint
    case appearance
    case appearanceSystem
    case appearanceLight
    case appearanceDark
    case language
    case selectFolderFirst
    case noScannableFiles
    case noResultsToExport
    case failedExportJSON
    case failedExportCSV
    case filesFailedScan
    case cannotEnumerate
    case parseIssuesSummary
    case updates
    case versionLabel
    case checkForUpdates
    case upToDate
    case updateAvailable
    case updateBadge
    case updateAvailableHint
    case openReleasePage
    case copyKey
    case openInXcode
    case revealInFinder
    case interpolatedBadge
}

enum L10n {
    static var language: AppLanguage = .english

    static func string(_ key: L10nKey, language: AppLanguage = language) -> String {
        switch language {
        case .english: return english(key)
        case .chineseSimplified: return chinese(key)
        }
    }

    static func t(_ key: L10nKey) -> String {
        string(key)
    }

    private static func english(_ key: L10nKey) -> String {
        switch key {
        case .brandSubtitle: return "Literal audit for Swift & ObjC"
        case .target: return "TARGET"
        case .chooseFolder: return "Choose Project Folder"
        case .changeFolder: return "Change Folder"
        case .startScan: return "Start Scan"
        case .scanning: return "Scanning…"
        case .session: return "SESSION"
        case .found: return "Found"
        case .localized: return "Localized"
        case .pickHint: return "Pick a folder, then scan.\nExports stay local."
        case .notice: return "Notice"
        case .ok: return "OK"
        case .noScanYet: return "No scan yet"
        case .emptyHint: return "Choose a project on the left, then run a scan to list string literals and localization hints."
        case .scanningProject: return "Scanning project…"
        case .noMatches: return "No matches"
        case .noMatchesHint: return "Try another filter or search term."
        case .filterPlaceholder: return "Filter content or path"
        case .filterAll: return "All"
        case .filterLocalized: return "Localized"
        case .filterPlain: return "Plain"
        case .exportJSON: return "JSON"
        case .exportCSV: return "CSV"
        case .exportMenu: return "Export"
        case .exportXCStrings: return "String Catalog (.xcstrings)"
        case .exportStrings: return "Strings (.strings)"
        case .failedExportXCStrings: return "Failed to export .xcstrings: %@"
        case .failedExportStrings: return "Failed to export .strings: %@"
        case .stringsCount: return "%@ of %@ strings"
        case .localizedBadge: return "LOCALIZED"
        case .catalogMissingBadge: return "NOT IN CATALOG"
        case .localizeFunctions: return "Localize wrappers"
        case .localizeFunctionsHint: return "Comma-separated, e.g. L10n.t,tr"
        case .appearance: return "Appearance"
        case .appearanceSystem: return "System"
        case .appearanceLight: return "Light"
        case .appearanceDark: return "Dark"
        case .language: return "Language"
        case .selectFolderFirst: return "Please select a folder first"
        case .noScannableFiles: return "No scannable .swift, .m, or .h files found in the selected folder"
        case .noResultsToExport: return "No results to export"
        case .failedExportJSON: return "Failed to export JSON: %@"
        case .failedExportCSV: return "Failed to export CSV: %@"
        case .filesFailedScan: return "%d files failed while scanning. Latest: %@"
        case .cannotEnumerate: return "Cannot enumerate directory contents"
        case .parseIssuesSummary: return "%d file(s) had parse/read issues during the scan"
        case .updates: return "Updates"
        case .versionLabel: return "Version %@"
        case .checkForUpdates: return "Check for Updates"
        case .upToDate: return "You're on the latest version (%@)."
        case .updateAvailable: return "Update available: %@"
        case .updateBadge: return "UPDATE"
        case .updateAvailableHint: return "A newer version is available — click to open the release page"
        case .openReleasePage: return "Open release page"
        case .copyKey: return "Copy string"
        case .openInXcode: return "Open in Xcode"
        case .revealInFinder: return "Reveal in Finder"
        case .interpolatedBadge: return "INTERPOLATED"
        }
    }

    private static func chinese(_ key: L10nKey) -> String {
        switch key {
        case .brandSubtitle: return "Swift / ObjC 字符串字面量审计"
        case .target: return "扫描目标"
        case .chooseFolder: return "选择项目文件夹"
        case .changeFolder: return "更换文件夹"
        case .startScan: return "开始扫描"
        case .scanning: return "扫描中…"
        case .session: return "本次结果"
        case .found: return "发现"
        case .localized: return "已本地化"
        case .pickHint: return "先选择文件夹，再开始扫描。\n导出文件保存在本地。"
        case .notice: return "提示"
        case .ok: return "好"
        case .noScanYet: return "尚未扫描"
        case .emptyHint: return "在左侧选择项目文件夹，然后开始扫描，即可列出字符串字面量与本地化提示。"
        case .scanningProject: return "正在扫描项目…"
        case .noMatches: return "无匹配结果"
        case .noMatchesHint: return "试试其他筛选条件或搜索词。"
        case .filterPlaceholder: return "按内容或路径筛选"
        case .filterAll: return "全部"
        case .filterLocalized: return "已本地化"
        case .filterPlain: return "普通"
        case .exportJSON: return "JSON"
        case .exportCSV: return "CSV"
        case .exportMenu: return "导出"
        case .exportXCStrings: return "String Catalog（.xcstrings）"
        case .exportStrings: return "Strings（.strings）"
        case .failedExportXCStrings: return "导出 .xcstrings 失败：%@"
        case .failedExportStrings: return "导出 .strings 失败：%@"
        case .stringsCount: return "%@ / %@ 条字符串"
        case .localizedBadge: return "已本地化"
        case .catalogMissingBadge: return "目录缺失"
        case .localizeFunctions: return "本地化包装"
        case .localizeFunctionsHint: return "逗号分隔，例如 L10n.t,tr"
        case .appearance: return "外观"
        case .appearanceSystem: return "跟随系统"
        case .appearanceLight: return "浅色"
        case .appearanceDark: return "深色"
        case .language: return "语言"
        case .selectFolderFirst: return "请先选择文件夹"
        case .noScannableFiles: return "所选文件夹中没有可扫描的 .swift / .m / .h 文件"
        case .noResultsToExport: return "没有可导出的结果"
        case .failedExportJSON: return "导出 JSON 失败：%@"
        case .failedExportCSV: return "导出 CSV 失败：%@"
        case .filesFailedScan: return "扫描时有 %d 个文件失败。最近一次：%@"
        case .cannotEnumerate: return "无法枚举目录内容"
        case .parseIssuesSummary: return "扫描中有 %d 个文件出现解析/读取问题"
        case .updates: return "更新"
        case .versionLabel: return "版本 %@"
        case .checkForUpdates: return "检查更新"
        case .upToDate: return "已是最新版本（%@）。"
        case .updateAvailable: return "发现新版本：%@"
        case .updateBadge: return "有更新"
        case .updateAvailableHint: return "发现新版本，点击打开发布页"
        case .openReleasePage: return "打开发布页"
        case .copyKey: return "复制字符串"
        case .openInXcode: return "在 Xcode 中打开"
        case .revealInFinder: return "在 Finder 中显示"
        case .interpolatedBadge: return "插值"
        }
    }

    static func format(_ key: L10nKey, _ args: CVarArg...) -> String {
        String(format: string(key), arguments: args)
    }
}
