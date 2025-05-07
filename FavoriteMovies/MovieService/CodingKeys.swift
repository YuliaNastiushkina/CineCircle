import Foundation

enum CodingKeys: String, CodingKey {
    case id, title, overview
    case posterPath = "poster_path"
    case voteAverage = "vote_average"
    case releaseDate = "release_date"
}
