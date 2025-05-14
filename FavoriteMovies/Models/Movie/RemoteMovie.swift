import Foundation

/// A movie that we fetch from the `api.themoviedb.org`.
struct RemoteMovie: Codable, Identifiable {
    /// Movie ID.
    let id: Int
    /// Movie title.
    var title: String
    /// A short description of the movie.
    var overview: String
    /// The relative path to the movie poster image.
    var posterPath: String?
    /// The average rating of the movie.
    var voteAverage: Double
    /// The release date of the movie in `"yyyy-MM-dd"` format.
    var releaseDate: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
    }
}
