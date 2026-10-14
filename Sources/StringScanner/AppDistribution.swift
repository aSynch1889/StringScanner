import Foundation

/// Build / runtime channel. App Store builds set the `APP_STORE` compilation flag.
enum AppDistribution {
    static var isAppStore: Bool {
        #if APP_STORE
        true
        #else
        // Receipt heuristic for archives that forgot the flag.
        if let receipt = Bundle.main.appStoreReceiptURL {
            return FileManager.default.fileExists(atPath: receipt.path)
        }
        return false
        #endif
    }

    /// Direct / notarized builds may check GitHub Releases; MAS uses App Store updates.
    static var supportsExternalUpdateCheck: Bool { !isAppStore }
}
