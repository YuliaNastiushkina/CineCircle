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
            cast = response.cast
            crew = response.crew
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
            images = response.backdrops
        } catch {
            print("Failed to fetch images: \(error)")
        }
    }
}
