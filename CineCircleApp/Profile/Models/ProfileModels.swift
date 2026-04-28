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
