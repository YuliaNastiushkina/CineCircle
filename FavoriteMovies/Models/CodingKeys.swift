import Foundation

enum CodingKeys: String, CodingKey {
    case id
    case title
    case overview
    case posterPath = "poster_path"
    case voteAverage = "vote_average"
    case releaseDate = "release_date"
}
