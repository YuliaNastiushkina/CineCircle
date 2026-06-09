@testable import CineCircle
import XCTest

@MainActor
class MovieListViewModelTests: XCTestCase {
    func testFetchAllMoviesUsesDiscoverEndpoint() async {
        // Given
        let mockClient = MockAPIClient { path, query in
            XCTAssertEqual(path, "discover/movie")
            XCTAssertEqual(query["sort_by"], "popularity.desc")
            XCTAssertNil(query["with_genres"])
            return MovieResponse(results: [], page: 1, totalResults: 0, totalPages: 1)
        }
        let viewModel = MovieListViewModel(client: mockClient)

        // When
        await viewModel.fetchAllMovies()

        // Then
        XCTAssertEqual(viewModel.selectedFilter, .all)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchPopularMoviesSuccess() async throws {
        // Given
        let expectedMovies = [
            RemoteMovie(id: 1, title: "Movie One", overview: "", posterPath: nil, voteAverage: 7.0, voteCount: 100, releaseDate: "2025-01-01", originalLanguage: "en", genreIDs: []),
            RemoteMovie(id: 2, title: "Movie Two", overview: "", posterPath: nil, voteAverage: 8.0, voteCount: 200, releaseDate: "2025-01-02", originalLanguage: "en", genreIDs: []),
        ]

        let mockClient = MockAPIClient { path, _ in
            XCTAssertEqual(path, "movie/popular")
            return MovieResponse(results: expectedMovies, page: 1, totalResults: 2, totalPages: 1)
        }

        let viewModel = MovieListViewModel(client: mockClient)

        // When
        await viewModel.fetchPopularMovies()

        // Then
        XCTAssertEqual(viewModel.movies.count, expectedMovies.count)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.currentPage, 1)
        XCTAssertEqual(viewModel.totalPages, 1)
    }

    func testFetchPopularMoviesFailure() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            throw URLError(.badServerResponse)
        }
        let viewModel = MovieListViewModel(client: mockClient)

        // When
        await viewModel.fetchPopularMovies()

        // Then
        XCTAssertTrue(viewModel.movies.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testFetchNextPageIfNeededLoadsMoreMovies() async {
        // Given
        let pageOneMovies = [RemoteMovie(id: 1, title: "Movie One", overview: "", posterPath: nil, voteAverage: 7.0, voteCount: 100, releaseDate: "2025-01-01", originalLanguage: "en", genreIDs: [])]
        let pageTwoMovies = [RemoteMovie(id: 2, title: "Movie Two", overview: "", posterPath: nil, voteAverage: 8.0, voteCount: 200, releaseDate: "2025-01-02", originalLanguage: "en", genreIDs: [])]

        let mockClient = MockAPIClient { _, query in
            if query["page"] == "1" {
                MovieResponse(results: pageOneMovies, page: 1, totalResults: 2, totalPages: 2)
            } else {
                MovieResponse(results: pageTwoMovies, page: 2, totalResults: 2, totalPages: 2)
            }
        }

        let viewModel = MovieListViewModel(client: mockClient)

        // When
        await viewModel.fetchPopularMovies()
        await viewModel.fetchNextPageIfNeeded(currentMovie: viewModel.movies.last!)

        // Then
        XCTAssertEqual(viewModel.movies.count, 2)
        XCTAssertEqual(viewModel.movies.map(\.id), [1, 2])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSelectGenreUsesDiscoverEndpoint() async {
        // Given
        let movie = RemoteMovie(id: 3, title: "Action Movie", overview: "", posterPath: nil, voteAverage: 7.5, voteCount: 50, releaseDate: "2025-03-01", originalLanguage: "en", genreIDs: [28])
        let mockClient = MockAPIClient { path, query in
            XCTAssertEqual(path, "discover/movie")
            XCTAssertEqual(query["with_genres"], "28")
            XCTAssertEqual(query["sort_by"], "popularity.desc")
            XCTAssertEqual(query["page"], "1")
            return MovieResponse(results: [movie], page: 1, totalResults: 1, totalPages: 1)
        }
        let viewModel = MovieListViewModel(client: mockClient)

        // When
        await viewModel.selectGenre(.action)

        // Then
        XCTAssertEqual(viewModel.selectedGenre, .action)
        XCTAssertEqual(viewModel.movies.map(\.id), [3])
    }

    func testGenrePaginationRetainsSelectedGenre() async {
        // Given
        let pageOneMovie = RemoteMovie(id: 4, title: "Mystery One", overview: "", posterPath: nil, voteAverage: 7.0, voteCount: 10, releaseDate: "", originalLanguage: "en", genreIDs: [9648])
        let pageTwoMovie = RemoteMovie(id: 5, title: "Mystery Two", overview: "", posterPath: nil, voteAverage: 8.0, voteCount: 20, releaseDate: "", originalLanguage: "en", genreIDs: [9648])
        let mockClient = MockAPIClient { path, query in
            XCTAssertEqual(path, "discover/movie")
            XCTAssertEqual(query["with_genres"], "9648")
            if query["page"] == "1" {
                return MovieResponse(results: [pageOneMovie], page: 1, totalResults: 2, totalPages: 2)
            }
            return MovieResponse(results: [pageTwoMovie], page: 2, totalResults: 2, totalPages: 2)
        }
        let viewModel = MovieListViewModel(client: mockClient)

        // When
        await viewModel.selectGenre(.mystery)
        await viewModel.fetchNextPageIfNeeded(currentMovie: pageOneMovie)

        // Then
        XCTAssertEqual(viewModel.movies.map(\.id), [4, 5])
        XCTAssertEqual(viewModel.currentPage, 2)
    }

    func testDisplayedMoviesFilteringAndSorting() {
        // Given
        let movie1 = RemoteMovie(id: 1, title: "Z Movie", overview: "", posterPath: nil, voteAverage: 7.0, voteCount: 100, releaseDate: "", originalLanguage: "en", genreIDs: [])
        let movie2 = RemoteMovie(id: 2, title: "A Movie", overview: "", posterPath: nil, voteAverage: 8.0, voteCount: 200, releaseDate: "", originalLanguage: "en", genreIDs: [])
        let viewModel = MovieListViewModel()
        viewModel.movies = [movie1, movie2]

        // Filtering
        viewModel.filterText = "Z"
        XCTAssertEqual(viewModel.displayedMovies.count, 1)
        XCTAssertEqual(viewModel.displayedMovies.first?.title, "Z Movie")

        // Sorting
        viewModel.isSorted = true
        viewModel.filterText = ""
        let sorted = viewModel.displayedMovies
        XCTAssertEqual(sorted.first?.title, "A Movie")
        XCTAssertEqual(sorted.last?.title, "Z Movie")
    }

    func testDisplayedMoviesShowSavedOnly() {
        // Given
        let movie1 = RemoteMovie(id: 1, title: "Movie 1", overview: "", posterPath: nil, voteAverage: 7.0, voteCount: 100, releaseDate: "", originalLanguage: "en", genreIDs: [])
        let movie2 = RemoteMovie(id: 2, title: "Movie 2", overview: "", posterPath: nil, voteAverage: 8.0, voteCount: 200, releaseDate: "", originalLanguage: "en", genreIDs: [])
        let viewModel = MovieListViewModel()
        viewModel.movies = [movie1, movie2]
        viewModel.savedIDs = [2]
        viewModel.showSavedOnly = true

        // When
        let filtered = viewModel.displayedMovies

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, 2)
    }
}
