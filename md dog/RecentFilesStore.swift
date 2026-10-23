//
//  RecentFilesStore.swift
//  md dog
//
//  Remembers recently opened files as security-scoped bookmarks so they can
//  be reopened later without showing the file picker again.
//

import Foundation

struct RecentFile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var bookmark: Data
    var lastOpened: Date
}

@MainActor
@Observable
final class RecentFilesStore {
    static let maxCount = 20

    private(set) var files: [RecentFile]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key = "recentFiles.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([RecentFile].self, from: data) {
            files = decoded
        } else {
            files = []
        }
    }

    /// Records `url` as the most recently opened file.
    func record(_ url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer { if canAccess { url.stopAccessingSecurityScopedResource() } }
        guard let bookmark = try? url.bookmarkData() else { return }

        let name = url.lastPathComponent
        let existing = files.first { entry in
            guard let resolved = Self.resolve(entry.bookmark)?.url else { return false }
            return resolved.standardizedFileURL == url.standardizedFileURL
        }
        files.removeAll { $0.id == existing?.id }
        files.insert(
            RecentFile(id: existing?.id ?? UUID(), name: name, bookmark: bookmark, lastOpened: .now),
            at: 0
        )
        if files.count > Self.maxCount {
            files.removeLast(files.count - Self.maxCount)
        }
        persist()
    }

    /// Resolves the stored bookmark, refreshing it when the system reports it stale.
    /// Returns nil when the file can no longer be found.
    func url(for file: RecentFile) -> URL? {
        guard let resolved = Self.resolve(file.bookmark) else { return nil }
        if resolved.isStale, let index = files.firstIndex(of: file) {
            let canAccess = resolved.url.startAccessingSecurityScopedResource()
            defer { if canAccess { resolved.url.stopAccessingSecurityScopedResource() } }
            if let fresh = try? resolved.url.bookmarkData() {
                files[index].bookmark = fresh
                persist()
            }
        }
        return resolved.url
    }

    func remove(_ file: RecentFile) {
        files.removeAll { $0.id == file.id }
        persist()
    }

    private static func resolve(_ bookmark: Data) -> (url: URL, isStale: Bool)? {
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
            return nil
        }
        return (url, isStale)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(files) else { return }
        defaults.set(data, forKey: key)
    }
}
