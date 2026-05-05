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

    func toggleWatched(movieId: Int, userId: String, title: String, posterPath: String?) {
        impl.toggle(movieId: movieId, userId: userId, title: title, posterPath: posterPath)
    }

    func watchedCount(for userId: String) -> Int {
        impl.count(for: userId)
    }

    func allWatchedMovieIDs(for userId: String) -> [Int] {
        impl.allMovieIDs(for: userId)
    }

    func allWatchedMovies(for userId: String) -> [ProfileMovieSnapshot] {
        impl.allMovieSnapshots(for: userId)
    }
}
