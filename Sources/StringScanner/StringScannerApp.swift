import SwiftUI

@main
struct StringScannerApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .frame(minWidth: 960, minHeight: 640)
        }
        // Keep a real title bar so search / filter / export can live in the toolbar.
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 720)
    }
}
