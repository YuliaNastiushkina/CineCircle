import Foundation

/// Aggregated statistics for a user's movie activity.
struct MovieStats {
    /// Number of movies marked as watched
    var totalWatched: Int = 0
    /// Number of movies saved to watchlist
    var totalSaved: Int = 0
    /// Number of movie notes written
    var totalNotes: Int = 0
}
