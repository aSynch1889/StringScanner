import Foundation

/// Persists security-scoped bookmarks so sandboxed builds can reopen the last project folder.
enum SecurityScopedBookmarkStore {
    private static let key = "app.projectFolderBookmark"

    static func save(url: URL) {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // Bookmark is best-effort; scan still works for the current session.
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Resolves the stored bookmark and starts security-scoped access.
    /// Caller must eventually call `stopAccessingSecurityScopedResource()` on the returned URL.
    static func restore() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                save(url: url)
            }
            guard url.startAccessingSecurityScopedResource() else { return nil }
            return url
        } catch {
            clear()
            return nil
        }
    }
}
