import Foundation

enum MovieListFilter: Equatable {
    case all
    case popular
    case genre(MoviesGenre)
}

/// Responsible for managing and loading movie lists from TMDB.
@Observable
@MainActor
final class MovieListViewModel {
    var movies: [RemoteMovie] = []
    var errorMessage: String?
    var filterText = ""
    var isSorted = false
    var showSavedOnly = false
    var savedIDs: Set<Int> = []
    var selectedFilter: MovieListFilter = .all
    private(set) var isLoading = false

    var selectedGenre: MoviesGenre? {
        guard case let .genre(genre) = selectedFilter else { return nil }
        return genre
    }

    var displayedMovies: [RemoteMovie] {
        let searched = filterText.isEmpty
            ? movies
            : movies.filter { $0.title.localizedCaseInsensitiveContains(filterText) }

        let sorted = isSorted
            ? searched.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            : searched

        return showSavedOnly ? sorted.filter { savedIDs.contains($0.id) } : sorted
    }

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    /// Loads TMDB's broad movie catalog, ordered by popularity.
    func fetchAllMovies() async {
        await selectFilter(.all)
    }

    /// Loads TMDB's current popular movie feed.
    func fetchPopularMovies() async {
        await selectFilter(.popular)
    }

    /// Loads movies for a single TMDB genre.
    func selectGenre(_ genre: MoviesGenre?) async {
        await selectFilter(genre.map(MovieListFilter.genre) ?? .all)
    }

    /// Replaces the current list using the selected catalog filter.
    func selectFilter(_ filter: MovieListFilter) async {
        selectedFilter = filter
        movies = []
        currentPage = 1
        totalPages = 1
        errorMessage = nil
        isLoading = true

        let requestID = UUID()
        activeRequestID = requestID
        defer {
            if activeRequestID == requestID {
                isLoading = false
            }
        }

        do {
            let response = try await fetchPage(1, filter: filter)
            guard activeRequestID == requestID else { return }
            movies = response.results
            currentPage = response.page
            totalPages = response.totalPages
        } catch is CancellationError {
            return
        } catch {
            guard activeRequestID == requestID else { return }
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    /// Loads the next page for the active catalog filter.
    func fetchNextPageIfNeeded(currentMovie: RemoteMovie) async {
        guard let last = movies.last, last.id == currentMovie.id else { return }
        guard currentPage < totalPages, !isFetching else { return }

        isFetching = true
        let requestID = activeRequestID
        let filter = selectedFilter
        defer { isFetching = false }

        do {
            let response = try await fetchPage(currentPage + 1, filter: filter)
            guard activeRequestID == requestID, selectedFilter == filter else { return }
            addUniqueMovies(response.results)
            currentPage = response.page
            totalPages = response.totalPages
        } catch is CancellationError {
            return
        } catch {
            guard activeRequestID == requestID else { return }
            errorMessage = "Failed to load more movies: \(error.localizedDescription)"
        }
    }

    private let client: APIClientProtocol
    private(set) var currentPage = 1
    private(set) var totalPages = 1
    private var isFetching = false
    private var activeRequestID = UUID()

    private func fetchPage(_ page: Int, filter: MovieListFilter) async throws -> MovieResponse {
        var query = [
            "language": "en-US",
            "page": "\(page)",
        ]

        let path: String
        switch filter {
        case .popular:
            path = "movie/popular"
        case .all:
            path = "discover/movie"
            query["sort_by"] = "popularity.desc"
        case let .genre(genre):
            path = "discover/movie"
            query["with_genres"] = "\(genre.id)"
            query["sort_by"] = "popularity.desc"
        }

        return try await client.fetch(
            path: path,
            query: query,
            responseType: MovieResponse.self
        )
    }

    private func addUniqueMovies(_ newMovies: [RemoteMovie]) {
        let unique = newMovies.filter { newMovie in
            !movies.contains(where: { $0.id == newMovie.id })
        }
        movies.append(contentsOf: unique)
    }
}
