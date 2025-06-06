import Foundation

/// Responsible for managing and loading a list of popular movies.
/// It fetches data from the API and exposes it to the view layer.
@Observable
@MainActor
class MovieListViewModel {
    /// A list of popular movies fetched from the API.
    var movies: [RemoteMovie] = []
    /// An error message to be displayed if fetching fails.
    var errorMessage: String?

    /// Fetches the list of popular movies from the TMDB API.
    ///
    /// If the request is successful, the movies array is updated.
    /// If the request fails, an error message is set.
    func fetchPopularMovies() async {
        do {
            let response: MovieResponse = try await client.fetch(
                path: "movie/popular",
                query: ["language": "EN-US", "page": "1"],
                responseType: MovieResponse.self
            )
            movies = response.results
        } catch {
            print("Fetch error: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: Private interface.

    private let client = APIClient()
}
