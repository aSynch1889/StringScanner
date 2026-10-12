import Foundation

enum AppVersion {
    static let current = "1.1.0"
    static let githubOwner = "aSynch1889"
    static let githubRepo = "StringScanner"
    static var releasesAPI: URL {
        URL(string: "https://api.github.com/repos/\(githubOwner)/\(githubRepo)/releases/latest")!
    }
    static var releasesPage: URL {
        URL(string: "https://github.com/\(githubOwner)/\(githubRepo)/releases")!
    }
}
