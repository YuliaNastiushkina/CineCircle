/// Combined movie and TV credits for a person from TMDB.
struct ActorCombinedCreditsResponse: Decodable {
    let cast: [ActorCredit]
}

/// A movie or TV show credit for a person.
struct ActorCredit: Decodable, Identifiable, Hashable {
    static let movieMediaType = "movie"
    static let tvMediaType = "tv"

    let tmdbID: Int
    let title: String?
    let name: String?
    let mediaType: String
    let posterPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let character: String?
    let voteAverage: Double
    let voteCount: Int

    var id: String {
        "\(mediaType)-\(tmdbID)"
    }

    var displayTitle: String {
        title ?? name ?? "Untitled"
    }

    var displayYear: String {
        let date = releaseDate ?? firstAirDate ?? ""
        let year = String(date.prefix(4))
        return year.isEmpty ? "TBA" : year
    }

    var mediaLabel: String {
        mediaType == Self.tvMediaType ? "TV" : "Movie"
    }

    enum CodingKeys: String, CodingKey {
        case tmdbID = "id"
        case title
        case name
        case mediaType = "media_type"
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case character
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
