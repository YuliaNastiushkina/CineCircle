/// A detailed representation of a movie fetched from TMDB `/movie/{id}` endpoint.
struct RemoteMovieDetail: Decodable, Identifiable {
    /// The unique identifier of the movie.
    let id: Int
    /// The title of the movie.
    let title: String
    /// A brief description or synopsis of the movie.
    let overview: String
    /// Relative path to the movie poster image.
    let posterPath: String?
    /// Relative path to the movie backdrop image.
    let backdropPath: String?
    /// Average user rating of the movie.
    let voteAverage: Double
    /// Release date in `"yyyy-MM-dd"` format.
    let releaseDate: String
    /// Runtime of the movie in minutes.
    let runtime: Int?
    /// The original language of the movie (ISO 639-1 code).
    let originalLanguage: String
    /// List of genres the movie belongs to.
    let genres: [Genre]
    /// List of production companies involved in the movie.
    let productionCompanies: [ProductionCompany]

    struct Genre: Decodable, Identifiable {
        let id: Int
        let name: String
    }

    struct ProductionCompany: Decodable, Identifiable {
        let id: Int
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case runtime
        case originalLanguage = "original_language"
        case genres
        case productionCompanies = "production_companies"
    }
}
