import Foundation

// MARK: - Recent Activity Models

struct RecentActivity {
    let recentlyWatched: [RecentMovie]
    let watchlistItems: [WatchlistMovie]
    let customLists: [ProfileCustomList] // Using prefixed name to avoid conflicts
}

struct RecentMovie {
    let id: String
    let title: String
    let posterURL: String?
    let rating: Double?
    let watchedDate: Date
    let genre: String
}

struct WatchlistMovie {
    let id: String
    let title: String
    let posterURL: String?
    let addedDate: Date
    let priority: WatchlistPriority
}

enum WatchlistPriority: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var color: String {
        switch self {
        case .high: "red"
        case .medium: "orange"
        case .low: "gray"
        }
    }
}

struct ProfileCustomList: Codable { // Renamed to avoid conflicts
    let id: String
    var movieCount: Int
    let name: String
    let icon: String
    let createdDate: Date
}

struct ProfileMovieSnapshot: Identifiable, Hashable {
    let id: Int
    let title: String
    let posterPath: String?
    let createdAt: Date?
}

enum ProfileLibraryMediaItem: Identifiable {
    case movie(ProfileMovieSnapshot)
    case tvShow(TVShowLibraryRecord)

    var id: String {
        switch self {
        case let .movie(movie): "movie-\(movie.id)"
        case let .tvShow(show): "tv-\(show.id)"
        }
    }

    var title: String {
        switch self {
        case let .movie(movie): movie.title
        case let .tvShow(show): show.title
        }
    }

    var posterPath: String? {
        switch self {
        case let .movie(movie): movie.posterPath
        case let .tvShow(show): show.posterPath
        }
    }

    var date: Date {
        switch self {
        case let .movie(movie): movie.createdAt ?? .distantPast
        case let .tvShow(show): show.updatedAt
        }
    }
}
