import CoreData
import Foundation

/// A service responsible for managing private movie diary entries using Core Data.
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
    /// - Returns: An array of `MovieDiary` objects matching the movie and user.
    func fetchNotes(for movieId: Int, userId: String) -> [MovieDiary] {
        let request = MovieDiary.fetchRequest()
        request.predicate = NSPredicate(format: "movieID == %d AND userID == %@", movieId, userId)
        return (try? context.fetch(request)) ?? []
    }

    /// Returns the total number of notes for a given user.
    func notesCount(for userId: String) -> Int {
        let request = MovieDiary.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userId)
        return (try? context.count(for: request)) ?? 0
    }

    /// Returns all diary entries for a given user, sorted by watched date (newest first).
    func allNotes(for userId: String) -> [MovieDiary] {
        let request = MovieDiary.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userId)
        request.sortDescriptors = [
            NSSortDescriptor(key: "watchedDate", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false),
        ]
        return (try? context.fetch(request)) ?? []
    }

    /// Creates a new diary entry or updates the existing one for a given movie and user.
    /// - Returns: An optional error if the save operation fails.
    @discardableResult func createOrUpdateDiaryEntry(
        for movieId: Int,
        userId: String,
        draft: MovieDiaryEntryDraft
    ) -> Error? {
        let existingEntries = fetchNotes(for: movieId, userId: userId)
        let entry = existingEntries.first ?? MovieDiary(context: context)

        if entry.id == nil {
            entry.id = UUID()
            entry.createdAt = Date()
            entry.movieID = Int32(movieId)
            entry.userID = userId
        }

        entry.content = draft.privateReflection
        entry.movieTitle = draft.movieTitle
        entry.watchedDate = draft.watchedDate
        entry.watchType = draft.watchType.rawValue
        entry.watchedWith = draft.watchedWith.rawValue
        entry.mood = MovieDiaryMood.encoded(draft.moods)
        entry.hasSpoilers = draft.hasSpoilers

        do {
            try context.save()
            NotificationCenter.default.post(name: .userLibraryDidChange, object: nil)
            return nil
        } catch {
            return error
        }
    }

    /// Backward-compatible note save wrapper. New UI should use `createOrUpdateDiaryEntry`.
    @discardableResult func createOrUpdateNote(
        for movieId: Int,
        userId: String,
        content: String,
        movieTitle: String
    ) -> Error? {
        createOrUpdateDiaryEntry(
            for: movieId,
            userId: userId,
            draft: MovieDiaryEntryDraft(
                privateReflection: content,
                movieTitle: movieTitle,
                watchedDate: Date(),
                watchType: .firstWatch,
                moods: [],
                watchedWith: .alone,
                hasSpoilers: false
            )
        )
    }
}
