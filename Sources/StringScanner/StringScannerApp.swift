import SwiftUI

@main
struct StringScannerApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var updateStatus = UpdateStatus()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(updateStatus)
                .frame(minWidth: 960, minHeight: 640)
                .task {
                    await updateStatus.checkOnLaunch()
                }
        }
        // Keep a real title bar so appearance / language / search live in the toolbar.
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 720)
    }
}
