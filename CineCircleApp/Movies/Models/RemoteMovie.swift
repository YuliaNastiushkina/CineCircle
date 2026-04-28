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
    /// Total number of votes.
    var voteCount: Int
    /// The release date of the movie in `"yyyy-MM-dd"` format.
    var releaseDate: String
    /// The original language of the movie (ISO 639-1 code).
    var originalLanguage: String
    /// Genre identifiers returned by TMDB for list endpoints.
    var genreIDs: [Int]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case originalLanguage = "original_language"
        case genreIDs = "genre_ids"
    }
}
