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

    func testDisplayedMoviesSavedOnlyFilteringAndSorting() {
        // Given
        let movie1 = RemoteMovie(id: 1, title: "Z Movie", overview: "", posterPath: nil, voteAverage: 7.0, voteCount: 100, releaseDate: "", originalLanguage: "en", genreIDs: [])
        let movie2 = RemoteMovie(id: 2, title: "A Movie", overview: "", posterPath: nil, voteAverage: 8.0, voteCount: 200, releaseDate: "", originalLanguage: "en", genreIDs: [])
        let viewModel = MovieListViewModel()
        viewModel.movies = [movie1, movie2]
        viewModel.savedIDs = [1, 2]
        viewModel.showSavedOnly = true

        // Filtering
        viewModel.filterText = "Z Movi"
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

    func testOneCharacterSearchDoesNotCallSearchEndpoint() async throws {
        let mockClient = MockAPIClient { _, _ in
            XCTFail("One-character search should not hit the network")
            return MovieResponse(results: [], page: 1, totalResults: 0, totalPages: 1)
        }
        let viewModel = MovieListViewModel(client: mockClient)

        viewModel.filterText = "u"
        viewModel.scheduleSearch()
        try await Task.sleep(nanoseconds: 450_000_000)

        XCTAssertTrue(viewModel.displayedMovies.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearchMoviesUsesSearchEndpoint() async throws {
        let movie = RemoteMovie(id: 7, title: "Interstellar", overview: "", posterPath: nil, voteAverage: 8.7, voteCount: 500, releaseDate: "2014-11-07", originalLanguage: "en", genreIDs: [])
        let mockClient = MockAPIClient { path, query in
            XCTAssertEqual(path, "search/movie")
            XCTAssertEqual(query["query"], "interstelar")
            XCTAssertEqual(query["page"], "1")
            return MovieResponse(results: [movie], page: 1, totalResults: 1, totalPages: 1)
        }
        let viewModel = MovieListViewModel(client: mockClient)

        viewModel.filterText = "interstelar"
        viewModel.scheduleSearch()
        try await Task.sleep(nanoseconds: 450_000_000)

        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [7])
        XCTAssertFalse(viewModel.isSearching)
    }

    func testEnterAIModeDoesNotEraseNormalMovies() {
        let movie = makeMovie(id: 1, title: "Catalog Movie")
        let viewModel = MovieListViewModel()
        viewModel.movies = [movie]
        viewModel.filterText = "catalog"
        viewModel.searchResults = [movie]

        viewModel.enterAIMode()

        XCTAssertTrue(viewModel.isAIMode)
        XCTAssertEqual(viewModel.movies.map(\.id), [1])
        XCTAssertTrue(viewModel.filterText.isEmpty)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertTrue(viewModel.displayedMovies.isEmpty)
    }

    func testExitAIModeRestoresNormalListBehavior() async {
        let catalogMovie = makeMovie(id: 1, title: "Catalog Movie")
        let recommendationMovie = makeMovie(id: 2, title: "AI Movie")
        let viewModel = makeRecommendationViewModel(
            movieService: MockRecommendationMovieService(result: .success([recommendationMovie]))
        )
        viewModel.movies = [catalogMovie]
        viewModel.aiPromptText = "pirates"
        await viewModel.submitAIRecommendationPrompt()

        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [2])

        viewModel.exitAIMode()

        XCTAssertFalse(viewModel.isAIMode)
        XCTAssertTrue(viewModel.aiPromptText.isEmpty)
        XCTAssertTrue(viewModel.rankedRecommendationMovies.isEmpty)
        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [1])
    }

    func testSubmitAIRecommendationPromptStoresFirstFiveRecommendations() async {
        let recommendedMovies = (1...7).map { makeMovie(id: $0, title: "Movie \($0)") }
        let intent = MovieRecommendationIntent(
            genres: [.adventure],
            searchQueries: ["pirate adventure"],
            explanation: "Adventure matches."
        )
        let viewModel = makeRecommendationViewModel(
            intentService: MockRecommendationIntentService(result: .success(intent)),
            movieService: MockRecommendationMovieService(result: .success(recommendedMovies))
        )
        viewModel.aiPromptText = "pirates"

        await viewModel.submitAIRecommendationPrompt()

        XCTAssertTrue(viewModel.isAIMode)
        XCTAssertFalse(viewModel.isLoadingRecommendations)
        XCTAssertEqual(viewModel.rankedRecommendationMovies.map(\.id), Array(1...7))
        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [1, 2, 3, 4, 5])
        XCTAssertEqual(viewModel.recommendationExplanation, "Adventure matches.")
        XCTAssertNil(viewModel.recommendationErrorMessage)
    }

    func testExitAIModeIgnoresLateRecommendationResponse() async {
        let recommendationMovie = makeMovie(id: 2, title: "Late AI Movie")
        let viewModel = makeRecommendationViewModel(
            movieService: DelayedRecommendationMovieService(movies: [recommendationMovie], delayNanoseconds: 80_000_000)
        )
        viewModel.movies = [makeMovie(id: 1, title: "Catalog Movie")]
        viewModel.aiPromptText = "pirates"

        let submitTask = Task { await viewModel.submitAIRecommendationPrompt() }
        try? await Task.sleep(nanoseconds: 20_000_000)
        viewModel.exitAIMode()
        await submitTask.value

        XCTAssertFalse(viewModel.isAIMode)
        XCTAssertFalse(viewModel.isLoadingRecommendations)
        XCTAssertTrue(viewModel.rankedRecommendationMovies.isEmpty)
        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [1])
    }

    func testRecommendationPaginationMovesBetweenBatches() async {
        let recommendedMovies = (1...7).map { makeMovie(id: $0, title: "Movie \($0)") }
        let viewModel = makeRecommendationViewModel(
            movieService: MockRecommendationMovieService(result: .success(recommendedMovies))
        )
        viewModel.aiPromptText = "movies"
        await viewModel.submitAIRecommendationPrompt()

        viewModel.showNextRecommendations()
        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [6, 7])
        XCTAssertTrue(viewModel.canShowPreviousRecommendations)
        XCTAssertFalse(viewModel.canShowNextRecommendations)

        viewModel.showPreviousRecommendations()
        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [1, 2, 3, 4, 5])
    }

    func testRecommendationPaginationStopsAfterMaximumVisibleBatches() async {
        let recommendedMovies = (1...20).map { makeMovie(id: $0, title: "Movie \($0)") }
        let viewModel = makeRecommendationViewModel(
            movieService: MockRecommendationMovieService(result: .success(recommendedMovies))
        )
        viewModel.aiPromptText = "movies"
        await viewModel.submitAIRecommendationPrompt()

        viewModel.showNextRecommendations()
        viewModel.showNextRecommendations()
        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [11, 12, 13, 14, 15])
        XCTAssertFalse(viewModel.canShowNextRecommendations)
        XCTAssertTrue(viewModel.shouldSuggestRefiningAIRequest)

        viewModel.showNextRecommendations()
        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [11, 12, 13, 14, 15])
    }

    func testSubmitAIRecommendationPromptFallsBackWhenIntentServiceFails() async {
        let fallbackMovie = makeMovie(id: 9, title: "Fallback Movie")
        let viewModel = makeRecommendationViewModel(
            intentService: MockRecommendationIntentService(result: .failure(MovieRecommendationError.malformedResponse)),
            fallbackIntentService: MockRecommendationIntentService(result: .success(MovieRecommendationIntent(searchQueries: ["fallback"]))),
            movieService: MockRecommendationMovieService(result: .success([fallbackMovie]))
        )
        viewModel.aiPromptText = "fallback please"

        await viewModel.submitAIRecommendationPrompt()

        XCTAssertEqual(viewModel.displayedMovies.map(\.id), [9])
        XCTAssertEqual(viewModel.recommendationErrorMessage, "AI suggestions are unavailable. Showing search results instead.")
    }

    func testSubmitAIRecommendationPromptValidatesEmptyPrompt() async {
        let viewModel = makeRecommendationViewModel()
        viewModel.aiPromptText = "   "

        await viewModel.submitAIRecommendationPrompt()

        XCTAssertTrue(viewModel.rankedRecommendationMovies.isEmpty)
        XCTAssertEqual(viewModel.recommendationErrorMessage, MovieRecommendationError.emptyPrompt.localizedDescription)
    }

    func testClearAIRecommendationsResetsPromptResultsPaginationAndMessages() async {
        let recommendedMovies = (1...7).map { makeMovie(id: $0, title: "Movie \($0)") }
        let viewModel = makeRecommendationViewModel(
            intentService: MockRecommendationIntentService(result: .success(MovieRecommendationIntent(searchQueries: ["query"], explanation: "Matches."))),
            movieService: MockRecommendationMovieService(result: .success(recommendedMovies))
        )
        viewModel.aiPromptText = "family adventure"
        await viewModel.submitAIRecommendationPrompt()
        viewModel.showNextRecommendations()
        viewModel.recommendationErrorMessage = "Temporary warning"

        viewModel.clearAIRecommendations()

        XCTAssertTrue(viewModel.aiPromptText.isEmpty)
        XCTAssertTrue(viewModel.rankedRecommendationMovies.isEmpty)
        XCTAssertEqual(viewModel.visibleRecommendationStartIndex, 0)
        XCTAssertNil(viewModel.recommendationExplanation)
        XCTAssertNil(viewModel.recommendationErrorMessage)
        XCTAssertTrue(viewModel.isAIMode)
        XCTAssertTrue(viewModel.displayedMovies.isEmpty)
    }

    func testScheduleSearchDoesNothingInAIMode() {
        let searchMovie = makeMovie(id: 1, title: "Search Result")
        let viewModel = MovieListViewModel(
            client: MockAPIClient { _, _ in MovieResponse(results: [searchMovie], page: 1, totalResults: 1, totalPages: 1) }
        )
        viewModel.enterAIMode()
        viewModel.filterText = "query"

        viewModel.scheduleSearch()

        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertTrue(viewModel.displayedMovies.isEmpty)
    }

    func testSubmitAIRecommendationPromptShowsFallbackErrorWhenFallbackAlsoFails() async {
        let viewModel = makeRecommendationViewModel(
            intentService: MockRecommendationIntentService(result: .failure(MovieRecommendationError.malformedResponse)),
            fallbackIntentService: MockRecommendationIntentService(result: .failure(MovieRecommendationError.invalidIntent))
        )
        viewModel.aiPromptText = "find something specific"

        await viewModel.submitAIRecommendationPrompt()

        XCTAssertTrue(viewModel.rankedRecommendationMovies.isEmpty)
        XCTAssertNil(viewModel.recommendationExplanation)
        XCTAssertEqual(viewModel.recommendationErrorMessage, MovieRecommendationError.invalidIntent.localizedDescription)
    }

    private func makeRecommendationViewModel(
        intentService: MovieRecommendationServiceProtocol = MockRecommendationIntentService(result: .success(MovieRecommendationIntent(searchQueries: ["query"]))),
        fallbackIntentService: MovieRecommendationServiceProtocol = MockRecommendationIntentService(result: .success(MovieRecommendationIntent(searchQueries: ["fallback"]))),
        movieService: MovieRecommendationMovieServiceProtocol = MockRecommendationMovieService(result: .success([]))
    ) -> MovieListViewModel {
        MovieListViewModel(
            client: MockAPIClient { _, _ in MovieResponse(results: [], page: 1, totalResults: 0, totalPages: 1) },
            recommendationIntentService: intentService,
            fallbackRecommendationIntentService: fallbackIntentService,
            recommendationMovieService: movieService
        )
    }

    private func makeMovie(id: Int, title: String) -> RemoteMovie {
        RemoteMovie(
            id: id,
            title: title,
            overview: "Overview",
            posterPath: nil,
            voteAverage: 7,
            voteCount: 100,
            releaseDate: "2024-01-01",
            originalLanguage: "en",
            genreIDs: []
        )
    }
}

private struct MockRecommendationIntentService: MovieRecommendationServiceProtocol {
    let result: Result<MovieRecommendationIntent, Error>

    func recommendationIntent(for _: String) async throws -> MovieRecommendationIntent {
        try result.get()
    }
}

private struct MockRecommendationMovieService: MovieRecommendationMovieServiceProtocol {
    let result: Result<[RemoteMovie], Error>

    func rankedMovies(for _: MovieRecommendationIntent) async throws -> [RemoteMovie] {
        try result.get()
    }
}

private struct DelayedRecommendationMovieService: MovieRecommendationMovieServiceProtocol {
    let movies: [RemoteMovie]
    let delayNanoseconds: UInt64

    func rankedMovies(for _: MovieRecommendationIntent) async throws -> [RemoteMovie] {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return movies
    }
}
