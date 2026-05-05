import CoreData

extension Notification.Name {
    static let userLibraryDidChange = Notification.Name("userLibraryDidChange")
}

/// Generic service to manage movie flags in Core Data (e.g., watched or saved movies).
/// - Parameter Entity: The Core Data entity type conforming to `MovieFlagEntity`.
final class MovieFlagService<Entity: MovieFlagEntity> {
    private let context: NSManagedObjectContext

    /// Initializes the service with a Core Data context.
    /// - Parameter context: The Core Data managed object context.
    init(context: NSManagedObjectContext) { self.context = context }

    /// Checks whether a flag exists for a given movie and user.
    /// - Parameters:
    ///   - movieId: The movie's ID.
    ///   - userId: The user's ID.
    /// - Returns: `true` if the flag exists, otherwise `false`.
    func isSet(movieId: Int, userId: String) -> Bool {
        let request = Entity.fetchRequest()
        request.predicate = NSPredicate(format: "movieID == %d AND userID == %@", movieId, userId)
        return (try? context.fetch(request).first) != nil
    }

    /// Returns the total number of flagged movies for a given user.
    /// - Parameter userId: The user’s ID.
    /// - Returns: The count of flagged movies.
    func count(for userId: String) -> Int {
        let request = Entity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userId)
        return (try? context.count(for: request)) ?? 0
    }

    /// Returns all movie IDs flagged for a given user.
    /// - Parameter userId: The user’s ID.
    /// - Returns: An array of movie IDs.
    func allMovieIDs(for userId: String) -> [Int] {
        let request = Entity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        guard let results = try? context.fetch(request) as? [Entity] else { return [] }
        return sortedResults(results).map { Int($0.movieID) }
    }

    func allMovieSnapshots(for userId: String) -> [ProfileMovieSnapshot] {
        let request = Entity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        guard let results = try? context.fetch(request) as? [Entity] else { return [] }

        return sortedResults(results).map { entity in
            ProfileMovieSnapshot(
                id: Int(entity.movieID),
                title: entity.title ?? "Movie #\(entity.movieID)",
                posterPath: entity.posterPath,
                createdAt: entity.createdAt
            )
        }
    }

    /// Toggles the flag for a movie and user: creates the record if it doesn’t exist, deletes it if it does.
    /// - Parameters:
    ///   - movieId: The movie’s ID.
    ///   - userId: The user’s ID.
    func toggle(movieId: Int, userId: String, title: String, posterPath: String?) {
        let request = Entity.fetchRequest()
        request.predicate = NSPredicate(format: "movieID == %d AND userID == %@", movieId, userId)
        if let existing = try? context.fetch(request).first as? Entity {
            context.delete(existing)
        } else {
            let new = Entity(context: context)
            new.id = UUID()
            new.movieID = Int32(movieId)
            new.userID = userId
            new.title = title
            new.posterPath = posterPath
            new.createdAt = Date()
        }
        try? context.save()
        NotificationCenter.default.post(name: .userLibraryDidChange, object: nil)
    }

    private func sortedResults(_ results: [Entity]) -> [Entity] {
        results.sorted { lhs, rhs in
            switch (lhs.createdAt, rhs.createdAt) {
            case let (leftDate?, rightDate?):
                leftDate > rightDate
            case (_?, nil):
                true
            case (nil, _?):
                false
            case (nil, nil):
                Int(lhs.movieID) > Int(rhs.movieID)
            }
        }
    }
}
