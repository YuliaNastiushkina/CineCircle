import CoreData
import Foundation

/// Removes locally stored app data for one authenticated Firebase user.
final class UserLocalDataCleanupService {
    static let shared = UserLocalDataCleanupService(
        context: CoreDataManager.shared.context,
        defaults: .standard
    )

    private let context: NSManagedObjectContext
    private let defaults: UserDefaults

    init(context: NSManagedObjectContext, defaults: UserDefaults) {
        self.context = context
        self.defaults = defaults
    }

    func deleteLocalData(for userId: String) {
        deleteManagedObjects(entityName: "WatchedMovie", userId: userId)
        deleteManagedObjects(entityName: "SavedMovie", userId: userId)
        deleteManagedObjects(entityName: "MovieDiary", userId: userId)

        removeExactDefaultsKeys(for: userId)
        removeDefaultsKeys(prefixes: [
            "tv_watched_episodes_\(userId)_",
            "tv_watched_episodes_summary_\(userId)_",
        ])

        saveContextIfNeeded()
        notifyUserDataChanged(userId: userId)
    }

    private func deleteManagedObjects(entityName: String, userId: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "userID == %@", userId)

        do {
            let objects = try context.fetch(request)
            objects.forEach(context.delete)
        } catch {
            return
        }
    }

    private func removeExactDefaultsKeys(for userId: String) {
        [
            ProfileUserDefaultsKeys.name(for: userId),
            ProfileUserDefaultsKeys.favoriteGenres(for: userId),
            "profile_image_\(userId)",
            "custom_lists_\(userId)",
            "tv_saved_shows_\(userId)",
            "tv_seen_shows_\(userId)",
        ].forEach(defaults.removeObject)
    }

    private func removeDefaultsKeys(prefixes: [String]) {
        let keys = defaults.dictionaryRepresentation().keys
        for key in keys where prefixes.contains(where: key.hasPrefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private func saveContextIfNeeded() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    private func notifyUserDataChanged(userId: String) {
        NotificationCenter.default.post(name: .userLibraryDidChange, object: nil)
        NotificationCenter.default.post(
            name: .profileFavoriteGenresDidChange,
            object: nil,
            userInfo: ["userID": userId]
        )
        NotificationCenter.default.post(
            name: .tvShowLibraryDidChange,
            object: nil,
            userInfo: ["userID": userId]
        )
        NotificationCenter.default.post(
            name: .tvEpisodeProgressDidChange,
            object: nil,
            userInfo: ["userID": userId]
        )
    }
}
