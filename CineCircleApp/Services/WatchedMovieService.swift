import CoreData
import Foundation

/// A service for managing the user's watched movies using Core Data.
final class WatchedMovieService {
    // MARK: Private interface

    private let context: NSManagedObjectContext

    // MARK: Internal interface

    /// The shared singleton instance of `WatchedMovieService`.
    static let shared = WatchedMovieService(context: CoreDataManager.shared.context)

    ///  Initializes a new instance of `WatchedMovieService`.
    /// - Parameter context: The Core Data context to use for operations.
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Checks whether the specified movie is marked as watched by the user.
    /// - Parameters:
    ///   - movieId: The ID of the movie.
    ///   - userId: The ID of the user.
    /// - Returns: `true` if the movie is marked as watched; otherwise, `false`.
    func isWatched(movieId: Int, userId: String) -> Bool {
        let request = WatchedMovie.fetchRequest()
        request.predicate = NSPredicate(format: "movieID == %d AND userID == %@", movieId, userId)
        return (try? context.fetch(request).first) != nil
    }

    /// Toggles the watched status of a movie for the user.
    ///
    /// If the movie is already marked as watched, the existing record will be removed.
    /// Otherwise, a new record will be created.
    /// - Parameters:
    ///   - movieId: The ID of the movie.
    ///   - userId: The ID of the user.
    func toggleWatched(movieId: Int, userId: String) {
        let request = WatchedMovie.fetchRequest()
        request.predicate = NSPredicate(format: "movieID == %d AND userID == %@", movieId, userId)

        if let existing = try? context.fetch(request).first {
            context.delete(existing)
        } else {
            let new = WatchedMovie(context: context)
            new.id = UUID()
            new.movieID = Int32(movieId)
            new.userID = userId
            new.createdAt = Date()
        }

        try? context.save()
    }
}
