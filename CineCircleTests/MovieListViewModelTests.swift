@testable import CineCircle
import XCTest

@MainActor
class MovieListViewModelTests: XCTestCase {
    func testFetchPopularMoviesSuccess() async throws {
        // Given
        let expectedMovies = [
            RemoteMovie(id: 1, title: "Movie One", overview: "", posterPath: nil, voteAverage: 7.0, releaseDate: "2025-01-01"),
            RemoteMovie(id: 2, title: "Movie Two", overview: "", posterPath: nil, voteAverage: 8.0, releaseDate: "2025-01-02"),
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
        let pageOneMovies = [RemoteMovie(id: 1, title: "Movie One", overview: "", posterPath: nil, voteAverage: 7.0, releaseDate: "2025-01-01")]
        let pageTwoMovies = [RemoteMovie(id: 2, title: "Movie Two", overview: "", posterPath: nil, voteAverage: 8.0, releaseDate: "2025-01-02")]

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

    func testDisplayedMoviesFilteringAndSorting() {
        // Given
        let movie1 = RemoteMovie(id: 1, title: "Z Movie", overview: "", posterPath: nil, voteAverage: 7.0, releaseDate: "")
        let movie2 = RemoteMovie(id: 2, title: "A Movie", overview: "", posterPath: nil, voteAverage: 8.0, releaseDate: "")
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
        let movie1 = RemoteMovie(id: 1, title: "Movie 1", overview: "", posterPath: nil, voteAverage: 7.0, releaseDate: "")
        let movie2 = RemoteMovie(id: 2, title: "Movie 2", overview: "", posterPath: nil, voteAverage: 8.0, releaseDate: "")
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
