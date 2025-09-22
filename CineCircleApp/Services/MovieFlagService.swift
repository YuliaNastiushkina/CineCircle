import CoreData

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

    /// Toggles the flag for a movie and user: creates the record if it doesn’t exist, deletes it if it does.
    /// - Parameters:
    ///   - movieId: The movie's ID.
    ///   - userId: The user's ID.
    func toggle(movieId: Int, userId: String) {
        let request = Entity.fetchRequest()
        request.predicate = NSPredicate(format: "movieID == %d AND userID == %@", movieId, userId)
        if let existing = try? context.fetch(request).first as? Entity {
            context.delete(existing)
        } else {
            let new = Entity(context: context)
            new.id = UUID()
            new.movieID = Int32(movieId)
            new.userID = userId
        }
        try? context.save()
    }
}
