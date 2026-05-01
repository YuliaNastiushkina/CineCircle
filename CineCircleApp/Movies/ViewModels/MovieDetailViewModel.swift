import Foundation

/// Responsible for managing and loading the details of a particular movie.
/// It fetches data from the API and exposes it to the view layer.
@MainActor
@Observable
class MovieDetailViewModel {
    // MARK: Private interface

    private let client: APIClientProtocol

    // MARK: Internal interface

    /// Initializes a new instance of `ActorListViewModel`.
    ///
    /// - Parameter client: An object conforming to `APIClientProtocol` used for making API requests.
    ///   Defaults to a shared instance of `APIClient`. This allows for dependency injection,
    ///   particularly useful for testing with a mock API client.
    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    /// The main details of the movie.
    var movieDetail: RemoteMovieDetail?
    /// A list of actors playing in the movie.
    var cast: [MovieCast] = []
    /// A list of the crew members in the movie.
    var crew: [MovieCrew] = []
    /// A gallery of images of the movie.
    var images: [MovieImage] = []
    /// Preferred trailer for the movie, if available.
    var trailer: MovieVideo?
    /// Indicates whether trailer loading has completed.
    var hasLoadedTrailer = false
    /// An error message to be displayed if fetching fails.
    var errorMessage: String?

    /// Fetches the main details of a movie by its ID.
    ///
    /// On success, updates `movieDetail`. On failure, sets `errorMessage`.
    /// - Parameter movieId: The ID of the movie for which details are requested.
    func fetchMovieDetails(for movieId: Int) async {
        do {
            let response: RemoteMovieDetail = try await client.fetch(
                path: "movie/\(movieId)",
                query: [:],
                responseType: RemoteMovieDetail.self
            )
            movieDetail = response
        } catch {
            errorMessage = "Failed to fetch movie details: \(error.localizedDescription)"
        }
    }

    /// Fetches cast and crew details for the specified movie.
    ///
    /// If the request is successful, `cast`, `director`, and `producer` will be updated.
    /// If the request fails, `errorMessage` will be set.
    /// - Parameter movieId: The ID of the movie for which details are requested.
    func fetchCastAndCrew(for movieId: Int) async {
        do {
            let response: MovieCreditsResponse = try await client.fetch(
                path: "movie/\(movieId)/credits",
                query: [:],
                responseType: MovieCreditsResponse.self
            )
            cast = uniqueCast(from: response.cast)
            crew = mergedCrew(from: response.crew)
        } catch {
            errorMessage = "Failed to fetch cast: \(error.localizedDescription)"
        }
    }

    /// Fetches backdrop images for the specified movie.
    ///
    /// On success, updates the `images` property with the fetched backdrops.
    /// On failure, prints an error message to the console.
    /// - Parameter movieId: The ID of the movie for which details are requested.
    func fetchMovieImages(for movieId: Int) async {
        do {
            let response: MovieImagesResponse = try await client.fetch(
                path: "movie/\(movieId)/images",
                query: [:],
                responseType: MovieImagesResponse.self
            )
            images = uniqueImages(from: response.backdrops)
        } catch {
            print("Failed to fetch images: \(error)")
        }
    }

    /// Fetches available videos and stores the preferred trailer.
    /// - Parameter movieId: The ID of the movie for which videos are requested.
    func fetchMovieTrailer(for movieId: Int) async {
        hasLoadedTrailer = false

        do {
            let response: MovieVideosResponse = try await client.fetch(
                path: "movie/\(movieId)/videos",
                query: [:],
                responseType: MovieVideosResponse.self
            )
            trailer = preferredTrailer(from: response.results)
        } catch {
            print("Failed to fetch trailer: \(error)")
            trailer = nil
        }

        hasLoadedTrailer = true
    }

    /// Computed property that transforms raw movie/crew data into `DetailedInfoPresentation` ready for display in the UI.
    var detailsPresentation: DetailedInfoPresentation {
        let directors = CrewFormatter.names(for: ["Director"], in: crew)
        let producers = CrewFormatter.names(for: ["Producer"], in: crew)
        let screen = CrewFormatter.names(for: ["Writer", "Screenplay", "Story"], in: crew)

        let companies = MovieFormatter.commaJoined(movieDetail?.productionCompanies.map(\.name) ?? [])
        let genres = MovieFormatter.commaJoined(movieDetail?.genres.map(\.name) ?? [])
        let language = (movieDetail?.originalLanguage.uppercased() ?? "—").nonEmptyOrDash
        let release = (movieDetail?.releaseDate ?? "—").nonEmptyOrDash
        let runtime = MovieFormatter.runtimeText(minutes: movieDetail?.runtime)

        return .init(directors: directors,
                     producers: producers,
                     screenwriters: screen,
                     productionCompanies: companies,
                     genres: genres,
                     originalLanguage: language,
                     releaseDate: release,
                     runtime: runtime)
    }

    private func uniqueCast(from cast: [MovieCast]) -> [MovieCast] {
        var seenIDs = Set<Int>()

        return cast.filter { member in
            seenIDs.insert(member.id).inserted
        }
    }

    private func mergedCrew(from crew: [MovieCrew]) -> [MovieCrew] {
        var mergedByID: [Int: MovieCrew] = [:]
        var orderedIDs: [Int] = []

        for member in crew {
            if var existing = mergedByID[member.id] {
                let mergedJobs = mergeJobs(existing.job, member.job)
                existing = MovieCrew(
                    id: existing.id,
                    name: existing.name,
                    job: mergedJobs,
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

    private func uniqueImages(from images: [MovieImage]) -> [MovieImage] {
        var seenPaths = Set<String>()

        return images.filter { image in
            seenPaths.insert(image.filePath).inserted
        }
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
