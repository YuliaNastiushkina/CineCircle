import Foundation

struct TVShowProgressRecord: Identifiable, Hashable {
    let id: Int
    let watchedEpisodeCount: Int
    let updatedAt: Date
    let lastSeasonNumber: Int?
    let lastEpisodeNumber: Int?

    var lastEpisodeCode: String? {
        guard let lastSeasonNumber, let lastEpisodeNumber else { return nil }
        return "S\(lastSeasonNumber) E\(lastEpisodeNumber)"
    }
}

struct TVEpisodeProgressService {
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func watchedEpisodeIDs(userID: String, showID: Int) -> Set<Int> {
        Set(defaults.array(forKey: storageKey(userID: userID, showID: showID)) as? [Int] ?? [])
    }

    func trackedShows(userID: String) -> [TVShowProgressRecord] {
        trackedShowIDs(userID: userID)
            .compactMap { showID in
                let watchedCount = watchedEpisodeIDs(userID: userID, showID: showID).count
                guard watchedCount > 0 else { return nil }

                let summary = progressSummary(userID: userID, showID: showID)
                return TVShowProgressRecord(
                    id: showID,
                    watchedEpisodeCount: watchedCount,
                    updatedAt: summary?.updatedAt ?? .distantPast,
                    lastSeasonNumber: summary?.lastSeasonNumber,
                    lastEpisodeNumber: summary?.lastEpisodeNumber
                )
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func isWatched(episodeID: Int, userID: String, showID: Int) -> Bool {
        watchedEpisodeIDs(userID: userID, showID: showID).contains(episodeID)
    }

    func setWatched(
        _ watched: Bool,
        episodeID: Int,
        userID: String,
        showID: Int,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil
    ) {
        var watchedIDs = watchedEpisodeIDs(userID: userID, showID: showID)
        if watched {
            watchedIDs.insert(episodeID)
        } else {
            watchedIDs.remove(episodeID)
        }
        save(
            watchedIDs,
            userID: userID,
            showID: showID,
            lastSeasonNumber: watched ? seasonNumber : nil,
            lastEpisodeNumber: watched ? episodeNumber : nil
        )
    }

    func setSeasonWatched(_ watched: Bool, episodeIDs: [Int], userID: String, showID: Int) {
        var watchedIDs = watchedEpisodeIDs(userID: userID, showID: showID)
        if watched {
            watchedIDs.formUnion(episodeIDs)
        } else {
            watchedIDs.subtract(episodeIDs)
        }
        save(watchedIDs, userID: userID, showID: showID)
    }

    private let defaults: UserDefaults

    private func save(
        _ watchedIDs: Set<Int>,
        userID: String,
        showID: Int,
        lastSeasonNumber: Int? = nil,
        lastEpisodeNumber: Int? = nil
    ) {
        let key = storageKey(userID: userID, showID: showID)
        if watchedIDs.isEmpty {
            defaults.removeObject(forKey: key)
            defaults.removeObject(forKey: summaryKey(userID: userID, showID: showID))
        } else {
            defaults.set(watchedIDs.sorted(), forKey: key)
            saveProgressSummary(
                watchedCount: watchedIDs.count,
                userID: userID,
                showID: showID,
                lastSeasonNumber: lastSeasonNumber,
                lastEpisodeNumber: lastEpisodeNumber
            )
        }

        NotificationCenter.default.post(
            name: .tvEpisodeProgressDidChange,
            object: nil,
            userInfo: ["userID": userID, "showID": showID]
        )
    }

    private func saveProgressSummary(
        watchedCount: Int,
        userID: String,
        showID: Int,
        lastSeasonNumber: Int?,
        lastEpisodeNumber: Int?
    ) {
        let current = progressSummary(userID: userID, showID: showID)
        let summary = StoredProgressSummary(
            watchedCount: watchedCount,
            updatedAt: Date(),
            lastSeasonNumber: lastSeasonNumber ?? current?.lastSeasonNumber,
            lastEpisodeNumber: lastEpisodeNumber ?? current?.lastEpisodeNumber
        )

        guard let data = try? JSONEncoder().encode(summary) else { return }
        defaults.set(data, forKey: summaryKey(userID: userID, showID: showID))
    }

    private func trackedShowIDs(userID: String) -> [Int] {
        let prefix = storageKeyPrefix(userID: userID)
        return defaults.dictionaryRepresentation().keys.compactMap { key in
            guard key.hasPrefix(prefix) else { return nil }
            return Int(key.dropFirst(prefix.count))
        }
    }

    private func progressSummary(userID: String, showID: Int) -> StoredProgressSummary? {
        guard let data = defaults.data(forKey: summaryKey(userID: userID, showID: showID)) else { return nil }
        return try? JSONDecoder().decode(StoredProgressSummary.self, from: data)
    }

    private func storageKey(userID: String, showID: Int) -> String {
        "\(storageKeyPrefix(userID: userID))\(showID)"
    }

    private func storageKeyPrefix(userID: String) -> String {
        "tv_watched_episodes_\(userID)_"
    }

    private func summaryKey(userID: String, showID: Int) -> String {
        "tv_watched_episodes_summary_\(userID)_\(showID)"
    }
}

private struct StoredProgressSummary: Codable {
    let watchedCount: Int
    let updatedAt: Date
    let lastSeasonNumber: Int?
    let lastEpisodeNumber: Int?
}

extension Notification.Name {
    static let tvEpisodeProgressDidChange = Notification.Name("tvEpisodeProgressDidChange")
}
