import Foundation

struct RemoteTVShow: Decodable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let voteAverage: Double
    let voteCount: Int
    let firstAirDate: String
    let originalLanguage: String
    let genreIDs: [Int]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case firstAirDate = "first_air_date"
        case originalLanguage = "original_language"
        case genreIDs = "genre_ids"
    }
}

struct TVShowResponse: Decodable {
    let page: Int
    let results: [RemoteTVShow]
    let totalResults: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalResults = "total_results"
        case totalPages = "total_pages"
    }
}
