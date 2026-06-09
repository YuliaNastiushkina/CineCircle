import Foundation

struct TVEpisodeProgressService {
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func watchedEpisodeIDs(userID: String, showID: Int) -> Set<Int> {
        Set(defaults.array(forKey: storageKey(userID: userID, showID: showID)) as? [Int] ?? [])
    }

    func isWatched(episodeID: Int, userID: String, showID: Int) -> Bool {
        watchedEpisodeIDs(userID: userID, showID: showID).contains(episodeID)
    }

    func setWatched(_ watched: Bool, episodeID: Int, userID: String, showID: Int) {
        var watchedIDs = watchedEpisodeIDs(userID: userID, showID: showID)
        if watched {
            watchedIDs.insert(episodeID)
        } else {
            watchedIDs.remove(episodeID)
        }
        save(watchedIDs, userID: userID, showID: showID)
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

    private func save(_ watchedIDs: Set<Int>, userID: String, showID: Int) {
        defaults.set(watchedIDs.sorted(), forKey: storageKey(userID: userID, showID: showID))
        NotificationCenter.default.post(
            name: .tvEpisodeProgressDidChange,
            object: nil,
            userInfo: ["userID": userID, "showID": showID]
        )
    }

    private func storageKey(userID: String, showID: Int) -> String {
        "tv_watched_episodes_\(userID)_\(showID)"
    }
}

extension Notification.Name {
    static let tvEpisodeProgressDidChange = Notification.Name("tvEpisodeProgressDidChange")
}
