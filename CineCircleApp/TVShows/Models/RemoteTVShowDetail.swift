import Foundation

struct RemoteTVShowDetail: Decodable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let voteCount: Int
    let firstAirDate: String
    let lastAirDate: String?
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    let episodeRunTime: [Int]
    let genres: [Genre]
    let seasons: [RemoteTVSeasonSummary]

    struct Genre: Decodable, Identifiable {
        let id: Int
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case firstAirDate = "first_air_date"
        case lastAirDate = "last_air_date"
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case episodeRunTime = "episode_run_time"
        case genres
        case seasons
    }
}
