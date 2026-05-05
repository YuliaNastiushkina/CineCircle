import CoreData
import Foundation

/// A service responsible for managing movie notes using Core Data.
final class NoteService {
    // MARK: Private interface

    private let context: NSManagedObjectContext

    // MARK: Internal interface

    /// The shared singleton instance of `NoteService`.
    static let shared = NoteService(context: CoreDataManager.shared.context)

    /// Initializes a new instance of `NoteService`.
    /// - Parameter context: The Core Data context to use for operations.
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Fetches notes for a specific movie and user from the persistent store.
    /// - Parameters:
    ///   - movieId: The ID of the movie.
    ///   - userId: The ID of the user.
    /// - Returns: An array of `MovieNote` objects matching the movie and user.
    func fetchNotes(for movieId: Int, userId: String) -> [MovieNote] {
        let request = MovieNote.fetchRequest()
        request.predicate = NSPredicate(format: "movieID == %d AND userID == %@", movieId, userId)
        return (try? context.fetch(request)) ?? []
    }

    /// Returns the total number of notes for a given user.
    func notesCount(for userId: String) -> Int {
        let request = MovieNote.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userId)
        return (try? context.count(for: request)) ?? 0
    }

    /// Returns all notes for a given user, sorted by creation date (newest first).
    func allNotes(for userId: String) -> [MovieNote] {
        let request = MovieNote.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Creates a new note or updates the existing one for a given movie and user.
    /// - Parameters:
    ///   - movieId: The ID of the movie.
    ///   - userId: The ID of the user.
    ///   - content: The content of the note.
    /// - Returns: An optional error if the save operation fails.
    @discardableResult func createOrUpdateNote(
        for movieId: Int,
        userId: String,
        content: String,
        movieTitle: String
    ) -> Error? {
        let existingNotes = fetchNotes(for: movieId, userId: userId)

        if let existingNote = existingNotes.first {
            existingNote.content = content
            existingNote.movieTitle = movieTitle
        } else {
            let newNote = MovieNote(context: context)
            newNote.movieID = Int32(movieId)
            newNote.userID = userId
            newNote.content = content
            newNote.movieTitle = movieTitle
            newNote.id = UUID()
            newNote.createdAt = Date()
        }

        do {
            try context.save()
            NotificationCenter.default.post(name: .userLibraryDidChange, object: nil)
            return nil
        } catch {
            return error
        }
    }
}
