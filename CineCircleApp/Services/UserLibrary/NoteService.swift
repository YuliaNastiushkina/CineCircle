import CoreData
import Foundation

/// A service responsible for managing private diary entries using Core Data.
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

    /// Fetches diary entries for a specific target and user from the persistent store.
    /// - Parameters:
    ///   - target: The movie or TV episode target.
    ///   - userId: The ID of the user.
    /// - Returns: An array of `MovieDiary` objects matching the target and user.
    func fetchDiaryEntries(for target: MovieDiaryEntryTarget, userId: String) -> [MovieDiary] {
        let request = MovieDiary.fetchRequest()
        request.predicate = predicate(for: target, userId: userId)
        return (try? context.fetch(request)) ?? []
    }

    /// Fetches notes for a specific movie and user from the persistent store.
    /// - Parameters:
    ///   - movieId: The ID of the movie.
    ///   - userId: The ID of the user.
    /// - Returns: An array of `MovieDiary` objects matching the movie and user.
    func fetchNotes(for movieId: Int, userId: String) -> [MovieDiary] {
        fetchDiaryEntries(for: .movie(movieId: movieId), userId: userId)
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

    /// Returns episode IDs that already have diary entries for a specific TV show and user.
    func tvEpisodeDiaryEntryIDs(showId: Int, userId: String) -> Set<Int> {
        let request = MovieDiary.fetchRequest()
        request.predicate = NSPredicate(
            format: "showID == %d AND userID == %@ AND mediaType == %@",
            showId,
            userId,
            MovieDiaryMediaType.tvEpisode.rawValue
        )
        return Set(((try? context.fetch(request)) ?? []).map { Int($0.episodeID) })
    }

    /// Creates a new diary entry or updates the existing one for a given target and user.
    /// - Returns: An optional error if the save operation fails.
    @discardableResult func createOrUpdateDiaryEntry(
        for target: MovieDiaryEntryTarget,
        userId: String,
        draft: MovieDiaryEntryDraft
    ) -> Error? {
        let existingEntries = fetchDiaryEntries(for: target, userId: userId)
        let entry = existingEntries.first ?? MovieDiary(context: context)

        if entry.id == nil {
            entry.id = UUID()
            entry.createdAt = Date()
            entry.userID = userId
        }

        apply(target, to: entry)
        entry.content = draft.privateReflection
        entry.movieTitle = draft.title
        entry.parentTitle = draft.parentTitle
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

    /// Creates a new movie diary entry or updates the existing one for a given movie and user.
    /// - Returns: An optional error if the save operation fails.
    @discardableResult func createOrUpdateDiaryEntry(
        for movieId: Int,
        userId: String,
        draft: MovieDiaryEntryDraft
    ) -> Error? {
        createOrUpdateDiaryEntry(
            for: .movie(movieId: movieId),
            userId: userId,
            draft: draft
        )
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

    private func predicate(for target: MovieDiaryEntryTarget, userId: String) -> NSPredicate {
        switch target {
        case let .movie(movieId):
            NSPredicate(
                format: "movieID == %d AND userID == %@ AND (mediaType == nil OR mediaType == %@)",
                movieId,
                userId,
                MovieDiaryMediaType.movie.rawValue
            )
        case let .tvEpisode(showId, episodeId, _, _):
            NSPredicate(
                format: "showID == %d AND episodeID == %d AND userID == %@ AND mediaType == %@",
                showId,
                episodeId,
                userId,
                MovieDiaryMediaType.tvEpisode.rawValue
            )
        }
    }

    private func apply(_ target: MovieDiaryEntryTarget, to entry: MovieDiary) {
        entry.mediaType = target.mediaType.rawValue

        switch target {
        case let .movie(movieId):
            entry.movieID = Int32(movieId)
            entry.showID = 0
            entry.episodeID = 0
            entry.seasonNumber = 0
            entry.episodeNumber = 0
        case let .tvEpisode(showId, episodeId, seasonNumber, episodeNumber):
            entry.movieID = 0
            entry.showID = Int32(showId)
            entry.episodeID = Int32(episodeId)
            entry.seasonNumber = Int32(seasonNumber)
            entry.episodeNumber = Int32(episodeNumber)
        }
    }
}
