import CoreData
import Foundation

/// A service for managing the user's watched movies using Core Data.
final class WatchedMovieService {
    // MARK: - Private interface

    private let impl: MovieFlagService<WatchedMovie>

    // MARK: - Internal interface

    static let shared = WatchedMovieService(context: CoreDataManager.shared.context)

    init(context: NSManagedObjectContext) {
        impl = MovieFlagService<WatchedMovie>(context: context)
    }

    func isWatched(movieId: Int, userId: String) -> Bool {
        impl.isSet(movieId: movieId, userId: userId)
    }

    func toggleWatched(movieId: Int, userId: String) {
        impl.toggle(movieId: movieId, userId: userId)
    }
}
