import Foundation

struct RemoteTVSeasonSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int
    let posterPath: String?
    let airDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
        case airDate = "air_date"
    }
}

struct RemoteTVSeasonDetail: Decodable, Identifiable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodes: [RemoteTVEpisode]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case seasonNumber = "season_number"
        case episodes
    }
}

struct RemoteTVEpisode: Decodable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let episodeNumber: Int
    let seasonNumber: Int
    let airDate: String?
    let runtime: Int?
    let stillPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case airDate = "air_date"
        case runtime
        case stillPath = "still_path"
    }
}
