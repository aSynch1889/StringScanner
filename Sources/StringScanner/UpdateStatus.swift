import Foundation
import SwiftUI

@MainActor
final class UpdateStatus: ObservableObject {
    @Published private(set) var availableRelease: GitHubRelease?
    @Published private(set) var didCheck = false

    var hasUpdate: Bool { availableRelease != nil }

    var releaseURL: URL {
        availableRelease?.htmlURL ?? AppVersion.releasesPage
    }

    func checkOnLaunch() async {
        guard !didCheck else { return }
        switch await UpdateChecker.check() {
        case .available(let release):
            availableRelease = release
        case .upToDate, .failed:
            availableRelease = nil
        }
        didCheck = true
    }
}
