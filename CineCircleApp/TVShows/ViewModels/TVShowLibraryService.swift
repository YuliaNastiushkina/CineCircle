import Foundation

enum TVShowLibraryFlag: String {
    case saved
    case seen
}

struct TVShowLibraryRecord: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let posterPath: String?
    let updatedAt: Date
}

struct TVShowLibraryService {
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isSet(_ flag: TVShowLibraryFlag, showID: Int, userID: String) -> Bool {
        records(flag, userID: userID).contains { $0.id == showID }
    }

    func toggle(
        _ flag: TVShowLibraryFlag,
        showID: Int,
        userID: String,
        title: String,
        posterPath: String?
    ) {
        set(
            flag,
            isSet: !isSet(flag, showID: showID, userID: userID),
            showID: showID,
            userID: userID,
            title: title,
            posterPath: posterPath
        )
    }

    func set(
        _ flag: TVShowLibraryFlag,
        isSet: Bool,
        showID: Int,
        userID: String,
        title: String,
        posterPath: String?
    ) {
        var current = records(flag, userID: userID)
        if let index = current.firstIndex(where: { $0.id == showID }) {
            if isSet {
                let existing = current[index]
                guard existing.title != title || existing.posterPath != posterPath else { return }
                current[index] = TVShowLibraryRecord(
                    id: showID,
                    title: title,
                    posterPath: posterPath,
                    updatedAt: existing.updatedAt
                )
            } else {
                current.remove(at: index)
            }
        } else if isSet {
            current.insert(
                TVShowLibraryRecord(
                    id: showID,
                    title: title,
                    posterPath: posterPath,
                    updatedAt: Date()
                ),
                at: 0
            )
        } else {
            return
        }

        save(current, flag: flag, userID: userID)
        NotificationCenter.default.post(
            name: .tvShowLibraryDidChange,
            object: nil,
            userInfo: ["userID": userID, "showID": showID]
        )
    }

    func showIDs(_ flag: TVShowLibraryFlag, userID: String) -> Set<Int> {
        Set(records(flag, userID: userID).map(\.id))
    }

    func records(_ flag: TVShowLibraryFlag, userID: String) -> [TVShowLibraryRecord] {
        let key = storageKey(flag, userID: userID)
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([TVShowLibraryRecord].self, from: data) {
            return decoded.sorted { $0.updatedAt > $1.updatedAt }
        }

        let legacyIDs = defaults.array(forKey: key) as? [Int] ?? []
        return legacyIDs.map {
            TVShowLibraryRecord(id: $0, title: "TV Show #\($0)", posterPath: nil, updatedAt: .distantPast)
        }
    }

    private let defaults: UserDefaults

    private func save(_ records: [TVShowLibraryRecord], flag: TVShowLibraryFlag, userID: String) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey(flag, userID: userID))
    }

    private func storageKey(_ flag: TVShowLibraryFlag, userID: String) -> String {
        "tv_\(flag.rawValue)_shows_\(userID)"
    }
}

extension Notification.Name {
    static let tvShowLibraryDidChange = Notification.Name("tvShowLibraryDidChange")
}
