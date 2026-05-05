import CoreData
import Foundation

/// Service specifically for managing saved movies.
final class SavedMovieService {
    private let impl: MovieFlagService<SavedMovie>
    static let shared = SavedMovieService(context: CoreDataManager.shared.context)

    init(context: NSManagedObjectContext) {
        impl = MovieFlagService<SavedMovie>(context: context)
    }

    func isSaved(movieId: Int, userId: String) -> Bool { impl.isSet(movieId: movieId, userId: userId) }
    func toggleSaved(movieId: Int, userId: String, title: String, posterPath: String?) {
        impl.toggle(movieId: movieId, userId: userId, title: title, posterPath: posterPath)
    }

    func savedCount(for userId: String) -> Int { impl.count(for: userId) }
    func allSavedMovieIDs(for userId: String) -> [Int] { impl.allMovieIDs(for: userId) }
    func allSavedMovies(for userId: String) -> [ProfileMovieSnapshot] { impl.allMovieSnapshots(for: userId) }
}
