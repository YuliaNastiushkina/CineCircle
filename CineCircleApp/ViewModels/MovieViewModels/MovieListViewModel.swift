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
            currentPage = response.page
            totalPages = response.totalPages
        } catch {
            print("Fetch error: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    /// Loads the next page if the user has scrolled to the last item.
    /// - Parameter currentMovie: The movie that is currently being rendered.
    func fetchNextPageIfNeeded(currentMovie: RemoteMovie) async {
        guard let last = movies.last, last.id == currentMovie.id else { return }
        guard currentPage < totalPages, !isFetching else { return }

        isFetching = true
        defer { isFetching = false }

        do {
            let response: MovieResponse = try await client.fetch(
                path: "movie/popular",
                query: ["language": "en-US", "page": "\(currentPage + 1)"],
                responseType: MovieResponse.self
            )
            addUniqueMovies(response.results)
            currentPage = response.page
            totalPages = response.totalPages
        } catch {
            errorMessage = "Failed to load more actors: \(error.localizedDescription)"
        }
    }

    // MARK: Private interface.

    private let client = APIClient()
    private(set) var currentPage = 1
    private(set) var totalPages = 1
    private var isFetching = false

    private func addUniqueMovies(_ newMovie: [RemoteMovie]) {
        let unique = newMovie.filter { new in
            !movies.contains(where: { $0.id == new.id })
        }
        movies.append(contentsOf: unique)
    }
}
