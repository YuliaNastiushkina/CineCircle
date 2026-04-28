import CoreData
import Foundation

/// Service for managing user's custom movie lists
final class ProfileCustomListService { // Renamed to avoid conflicts
    private let context: NSManagedObjectContext

    static let shared = ProfileCustomListService(context: CoreDataManager.shared.context)

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Create a new custom list for a user
    func createList(name: String, icon: String, userId: String) -> ProfileCustomList? {
        let newList = ProfileCustomList(
            id: UUID().uuidString,
            movieCount: 0,
            name: name,
            icon: icon,
            createdDate: Date()
        )

        var existingLists = getUserLists(for: userId)
        existingLists.append(newList)
        saveUserLists(existingLists, for: userId)

        return newList
    }

    /// Get all custom lists for a user
    func getUserLists(for userId: String) -> [ProfileCustomList] {
        let key = "custom_lists_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let lists = try? JSONDecoder().decode([ProfileCustomList].self, from: data) else {
            return []
        }
        return lists
    }

    /// Save user lists to UserDefaults (temporary solution)
    private func saveUserLists(_ lists: [ProfileCustomList], for userId: String) {
        let key = "custom_lists_\(userId)"
        if let data = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Add movie to a custom list
    func addMovieToList(movieId _: Int, listId: String, userId: String) {
        var lists = getUserLists(for: userId)
        if let index = lists.firstIndex(where: { $0.id == listId }) {
            lists[index].movieCount += 1
            saveUserLists(lists, for: userId)
        }
    }

    /// Remove movie from a custom list
    func removeMovieFromList(movieId _: Int, listId: String, userId: String) {
        var lists = getUserLists(for: userId)
        if let index = lists.firstIndex(where: { $0.id == listId }) {
            lists[index].movieCount = max(0, lists[index].movieCount - 1)
            saveUserLists(lists, for: userId)
        }
    }

    /// Delete a custom list
    func deleteList(listId: String, userId: String) {
        var lists = getUserLists(for: userId)
        lists.removeAll { $0.id == listId }
        saveUserLists(lists, for: userId)
    }
}
