import Foundation

/// Service that aggregates stats from Core Data for the profile.
final class MovieStatsService {
    static let shared = MovieStatsService()

    private let watchedService: WatchedMovieService
    private let savedService: SavedMovieService
    private let noteService: NoteService

    init(
        watchedService: WatchedMovieService = .shared,
        savedService: SavedMovieService = .shared,
        noteService: NoteService = .shared
    ) {
        self.watchedService = watchedService
        self.savedService = savedService
        self.noteService = noteService
    }

    /// Calculate aggregate statistics for a user from Core Data.
    func calculateStats(for userId: String) -> MovieStats {
        MovieStats(
            totalWatched: watchedService.watchedCount(for: userId),
            totalSaved: savedService.savedCount(for: userId),
            totalNotes: noteService.notesCount(for: userId)
        )
    }
}
