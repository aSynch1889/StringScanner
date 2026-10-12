import Foundation

struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
    }
}

enum UpdateChecker {
    enum Result {
        case upToDate(current: String)
        case available(release: GitHubRelease)
        case failed(String)
    }

    static func check(session: URLSession = .shared) async -> Result {
        do {
            var request = URLRequest(url: AppVersion.releasesAPI)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("StringScanner/\(AppVersion.current)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 404 {
                return .failed("No GitHub release found yet")
            }
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            if isNewer(release.tagName, than: AppVersion.current) {
                return .available(release: release)
            }
            return .upToDate(current: AppVersion.current)
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// Compares loose semver tags like `v1.2.3` / `1.2.3`.
    static func isNewer(_ remoteTag: String, than local: String) -> Bool {
        let remote = normalize(remoteTag)
        let current = normalize(local)
        return compare(remote, current) == .orderedDescending
    }

    private static func normalize(_ value: String) -> [Int] {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutV = trimmed.hasPrefix("v") || trimmed.hasPrefix("V")
            ? String(trimmed.dropFirst())
            : trimmed
        return withoutV.split(separator: ".").prefix(3).map { Int($0) ?? 0 }
    }

    private static func compare(_ lhs: [Int], _ rhs: [Int]) -> ComparisonResult {
        let count = max(lhs.count, rhs.count)
        for index in 0..<count {
            let l = index < lhs.count ? lhs[index] : 0
            let r = index < rhs.count ? rhs[index] : 0
            if l != r {
                return l > r ? .orderedDescending : .orderedAscending
            }
        }
        return .orderedSame
    }
}
