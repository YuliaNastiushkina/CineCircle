import Foundation

struct ProfileTrackedShowLoadResult {
    let trackingShows: [ProfileTrackedTVShowItem]
    let completedShows: [TVShowLibraryRecord]
}

struct ProfileTrackedTVShowItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let posterPath: String?
    let watchedEpisodeCount: Int
    let totalEpisodeCount: Int?
    let updatedAt: Date
    let lastEpisodeCode: String?

    var progressValue: Double {
        guard let totalEpisodeCount, totalEpisodeCount > 0 else { return 0 }
        return min(Double(watchedEpisodeCount) / Double(totalEpisodeCount), 1)
    }

    var progressText: String {
        guard let totalEpisodeCount, totalEpisodeCount > 0 else {
            return "\(watchedEpisodeCount) watched"
        }
        return "\(watchedEpisodeCount) of \(totalEpisodeCount) watched"
    }

    var subtitle: String? {
        guard let lastEpisodeCode else { return nil }
        return "Last: \(lastEpisodeCode)"
    }
}
