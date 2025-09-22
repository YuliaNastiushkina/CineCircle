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
    func toggleSaved(movieId: Int, userId: String) { impl.toggle(movieId: movieId, userId: userId) }
}
