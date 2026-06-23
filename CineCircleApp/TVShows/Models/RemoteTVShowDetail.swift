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
    let tagline: String?
    /// Current airing status (e.g. "Returning Series", "Ended", "Canceled").
    let status: String?
    /// Show format as classified by TMDB (e.g. "Scripted", "Reality", "Miniseries", "Documentary").
    let type: String?
    let networks: [Network]
    let createdBy: [Creator]
    let originCountry: [String]
    let credits: MovieCreditsResponse?
    let videos: MovieVideosResponse?
    let images: MovieImagesResponse?

    /// Deduplicated cast list derived from credits.
    var cast: [MovieCast] {
        uniqueCast(from: credits?.cast ?? [])
    }

    /// Crew list with jobs merged per person, derived from credits.
    var crew: [MovieCrew] {
        mergedCrew(from: credits?.crew ?? [])
    }

    /// All deduplicated backdrop images for the show. Use `.prefix(n)` at the call site for inline previews.
    var galleryImages: [MovieImage] {
        uniqueImages(from: images?.backdrops ?? [])
    }

    /// Best available YouTube trailer or teaser, if any.
    var trailer: MovieVideo? {
        preferredTrailer(from: videos?.results ?? [])
    }

    struct Genre: Decodable, Identifiable {
        let id: Int
        let name: String
    }

    struct Network: Decodable, Identifiable {
        let id: Int
        let name: String
        let logoPath: String?
        let originCountry: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case logoPath = "logo_path"
            case originCountry = "origin_country"
        }
    }

    struct Creator: Decodable, Identifiable {
        let id: Int
        let name: String
        let profilePath: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case profilePath = "profile_path"
        }
    }

    init(
        id: Int,
        name: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        voteAverage: Double,
        voteCount: Int,
        firstAirDate: String,
        lastAirDate: String?,
        numberOfSeasons: Int,
        numberOfEpisodes: Int,
        episodeRunTime: [Int],
        genres: [Genre],
        seasons: [RemoteTVSeasonSummary],
        tagline: String? = nil,
        status: String? = nil,
        type: String? = nil,
        networks: [Network] = [],
        createdBy: [Creator] = [],
        originCountry: [String] = [],
        credits: MovieCreditsResponse? = nil,
        videos: MovieVideosResponse? = nil,
        images: MovieImagesResponse? = nil
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.firstAirDate = firstAirDate
        self.lastAirDate = lastAirDate
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.episodeRunTime = episodeRunTime
        self.genres = genres
        self.seasons = seasons
        self.tagline = tagline
        self.status = status
        self.type = type
        self.networks = networks
        self.createdBy = createdBy
        self.originCountry = originCountry
        self.credits = credits
        self.videos = videos
        self.images = images
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
        case tagline
        case status
        case type
        case networks
        case createdBy = "created_by"
        case originCountry = "origin_country"
        case credits
        case videos
        case images
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate) ?? ""
        lastAirDate = try container.decodeIfPresent(String.self, forKey: .lastAirDate)
        numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons) ?? 0
        numberOfEpisodes = try container.decodeIfPresent(Int.self, forKey: .numberOfEpisodes) ?? 0
        episodeRunTime = try container.decodeIfPresent([Int].self, forKey: .episodeRunTime) ?? []
        genres = try container.decodeIfPresent([Genre].self, forKey: .genres) ?? []
        seasons = try container.decodeIfPresent([RemoteTVSeasonSummary].self, forKey: .seasons) ?? []
        tagline = try container.decodeIfPresent(String.self, forKey: .tagline)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        networks = try container.decodeIfPresent([Network].self, forKey: .networks) ?? []
        createdBy = try container.decodeIfPresent([Creator].self, forKey: .createdBy) ?? []
        originCountry = try container.decodeIfPresent([String].self, forKey: .originCountry) ?? []
        credits = try container.decodeIfPresent(MovieCreditsResponse.self, forKey: .credits)
        videos = try container.decodeIfPresent(MovieVideosResponse.self, forKey: .videos)
        images = try container.decodeIfPresent(MovieImagesResponse.self, forKey: .images)
    }

    private func uniqueCast(from cast: [MovieCast]) -> [MovieCast] {
        var seenIDs = Set<Int>()
        return cast.filter { seenIDs.insert($0.id).inserted }
    }

    private func uniqueImages(from images: [MovieImage]) -> [MovieImage] {
        var seenPaths = Set<String>()
        return images.filter { seenPaths.insert($0.filePath).inserted }
    }

    private func mergedCrew(from crew: [MovieCrew]) -> [MovieCrew] {
        var mergedByID: [Int: MovieCrew] = [:]
        var orderedIDs: [Int] = []

        for member in crew {
            if var existing = mergedByID[member.id] {
                existing = MovieCrew(
                    id: existing.id,
                    name: existing.name,
                    job: mergeJobs(existing.job, member.job),
                    profilePath: existing.profilePath ?? member.profilePath
                )
                mergedByID[member.id] = existing
            } else {
                mergedByID[member.id] = member
                orderedIDs.append(member.id)
            }
        }

        return orderedIDs.compactMap { mergedByID[$0] }
    }

    private func mergeJobs(_ lhs: String, _ rhs: String) -> String {
        var orderedJobs: [String] = []
        var seenJobs = Set<String>()

        for job in (lhs + "," + rhs).split(separator: ",") {
            let trimmedJob = job.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedJob.isEmpty, seenJobs.insert(trimmedJob).inserted else { continue }
            orderedJobs.append(trimmedJob)
        }

        return orderedJobs.joined(separator: ", ")
    }

    private func preferredTrailer(from videos: [MovieVideo]) -> MovieVideo? {
        let youtubeVideos = videos.filter { $0.site == "YouTube" }
        return youtubeVideos.first(where: { $0.type == "Trailer" && $0.official })
            ?? youtubeVideos.first(where: { $0.type == "Trailer" })
            ?? youtubeVideos.first(where: { $0.type == "Teaser" })
            ?? youtubeVideos.first
    }
}
