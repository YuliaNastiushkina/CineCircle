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
    var searchResults: [RemoteMovie] = []
    var errorMessage: String?
    var filterText = ""
    var isSorted = false
    var showSavedOnly = false
    var savedIDs: Set<Int> = []
    var selectedFilter: MovieListFilter = .all
    var isAIMode = false
    var aiPromptText = ""
    private(set) var rankedRecommendationMovies: [RemoteMovie] = []
    private(set) var visibleRecommendationStartIndex = 0
    let visibleRecommendationLimit = 5
    var recommendationExplanation: String?
    var recommendationErrorMessage: String?
    private(set) var isLoading = false
    private(set) var isSearching = false
    private(set) var isLoadingRecommendations = false

    var selectedGenre: MoviesGenre? {
        guard case let .genre(genre) = selectedFilter else { return nil }
        return genre
    }

    var displayedMovies: [RemoteMovie] {
        if isAIMode {
            return visibleRecommendationMovies
        }

        let query = searchQuery
        let savedMovies = showSavedOnly ? movies.filter { savedIDs.contains($0.id) } : movies
        let baseMovies: [RemoteMovie] = if query.isEmpty {
            savedMovies
        } else if showSavedOnly {
            savedMovies.filter { FuzzyMatch.matches($0.title, query: query) }
        } else {
            searchResults
        }

        let sorted = isSorted
            ? baseMovies.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            : baseMovies

        return sorted
    }

    var visibleRecommendationMovies: [RemoteMovie] {
        guard visibleRecommendationStartIndex < rankedRecommendationMovies.count else { return [] }
        let endIndex = min(visibleRecommendationStartIndex + visibleRecommendationLimit, rankedRecommendationMovies.count)
        return Array(rankedRecommendationMovies[visibleRecommendationStartIndex..<endIndex])
    }

    var canShowNextRecommendations: Bool {
        visibleRecommendationStartIndex + visibleRecommendationLimit < rankedRecommendationMovies.count
    }

    var canShowPreviousRecommendations: Bool {
        visibleRecommendationStartIndex > 0
    }

    init(
        client: APIClientProtocol = APIClient(),
        recommendationIntentService: MovieRecommendationServiceProtocol = GeminiMovieRecommendationService(),
        fallbackRecommendationIntentService: MovieRecommendationServiceProtocol = FallbackMovieRecommendationService(),
        recommendationMovieService: MovieRecommendationMovieServiceProtocol = TMDBMovieRecommendationMovieService()
    ) {
        self.client = client
        self.recommendationIntentService = recommendationIntentService
        self.fallbackRecommendationIntentService = fallbackRecommendationIntentService
        self.recommendationMovieService = recommendationMovieService
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

    func scheduleSearch() {
        guard !isAIMode else { return }
        searchTask?.cancel()

        let query = searchQuery
        guard query.count >= 2 else {
            searchResults = []
            searchPage = 1
            searchTotalPages = 1
            isSearching = false
            return
        }

        let requestID = UUID()
        activeSearchRequestID = requestID
        isSearching = true
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
                try Task.checkCancellation()
                try await searchMovies(query: query, page: 1, replacingResults: true, requestID: requestID)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, activeSearchRequestID == requestID else { return }
                searchResults = []
                searchPage = 1
                searchTotalPages = 1
                errorMessage = "Failed to search movies: \(error.localizedDescription)"
                isSearching = false
            }
        }
    }

    /// Enters AI prompt mode without clearing the currently loaded movie catalog.
    func enterAIMode() {
        isAIMode = true
        filterText = ""
        searchTask?.cancel()
        searchResults = []
        isSearching = false
        recommendationErrorMessage = nil
    }

    /// Leaves AI prompt mode and clears recommendation-only state.
    func exitAIMode() {
        isAIMode = false
        clearAIRecommendations()
    }

    /// Clears current AI prompt, result, and pagination state.
    func clearAIRecommendations() {
        invalidateActiveRecommendationRequest()
        aiPromptText = ""
        rankedRecommendationMovies = []
        recommendationExplanation = nil
        recommendationErrorMessage = nil
        resetRecommendationPagination()
    }

    /// Generates recommendation intent and ranked TMDB movies for the current AI prompt.
    func submitAIRecommendationPrompt() async {
        let prompt = aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            recommendationErrorMessage = MovieRecommendationError.emptyPrompt.localizedDescription
            rankedRecommendationMovies = []
            resetRecommendationPagination()
            return
        }

        isAIMode = true
        isLoadingRecommendations = true
        recommendationErrorMessage = nil
        let requestID = UUID()
        activeRecommendationRequestID = requestID

        defer {
            if activeRecommendationRequestID == requestID {
                isLoadingRecommendations = false
            }
        }

        do {
            let intent = try await recommendationIntentService.recommendationIntent(for: prompt)
            let movies = try await recommendationMovieService.rankedMovies(for: intent)
            guard activeRecommendationRequestID == requestID else { return }
            rankedRecommendationMovies = movies
            recommendationExplanation = intent.explanation
            resetRecommendationPagination()
        } catch is CancellationError {
            return
        } catch {
            await loadFallbackRecommendations(prompt: prompt, requestID: requestID)
        }
    }

    func showNextRecommendations() {
        guard canShowNextRecommendations else { return }
        visibleRecommendationStartIndex += visibleRecommendationLimit
    }

    func showPreviousRecommendations() {
        guard canShowPreviousRecommendations else { return }
        visibleRecommendationStartIndex = max(0, visibleRecommendationStartIndex - visibleRecommendationLimit)
    }

    func resetRecommendationPagination() {
        visibleRecommendationStartIndex = 0
    }

    /// Loads the next page for the active catalog filter or active search query.
    func fetchNextPageIfNeeded(currentMovie: RemoteMovie) async {
        if !searchQuery.isEmpty, !showSavedOnly {
            await fetchNextSearchPageIfNeeded(currentMovie: currentMovie)
            return
        }

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
    private let recommendationIntentService: MovieRecommendationServiceProtocol
    private let fallbackRecommendationIntentService: MovieRecommendationServiceProtocol
    private let recommendationMovieService: MovieRecommendationMovieServiceProtocol
    private(set) var currentPage = 1
    private(set) var totalPages = 1
    private var isFetching = false
    private var activeRequestID = UUID()
    private var searchTask: Task<Void, Never>?
    private var activeSearchRequestID = UUID()
    private var searchPage = 1
    private var searchTotalPages = 1
    private var isFetchingSearch = false
    private var activeRecommendationRequestID = UUID()

    private var searchQuery: String {
        filterText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func invalidateActiveRecommendationRequest() {
        activeRecommendationRequestID = UUID()
        isLoadingRecommendations = false
    }

    private func loadFallbackRecommendations(prompt: String, requestID: UUID) async {
        do {
            let fallbackIntent = try await fallbackRecommendationIntentService.recommendationIntent(for: prompt)
            let movies = try await recommendationMovieService.rankedMovies(for: fallbackIntent)
            guard activeRecommendationRequestID == requestID else { return }
            rankedRecommendationMovies = movies
            recommendationExplanation = fallbackIntent.explanation
            recommendationErrorMessage = "AI suggestions are unavailable. Showing search results instead."
            resetRecommendationPagination()
        } catch is CancellationError {
            return
        } catch {
            guard activeRecommendationRequestID == requestID else { return }
            rankedRecommendationMovies = []
            recommendationExplanation = nil
            recommendationErrorMessage = error.localizedDescription
            resetRecommendationPagination()
        }
    }

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

    private func searchMovies(query: String, page: Int, replacingResults: Bool, requestID: UUID) async throws {
        let response: MovieResponse = try await client.fetch(
            path: "search/movie",
            query: [
                "language": "en-US",
                "page": "\(page)",
                "query": query,
            ],
            responseType: MovieResponse.self
        )

        guard activeSearchRequestID == requestID, query == searchQuery else { return }

        let rankedResults = FuzzyMatch.ranked(response.results, query: query, text: \.title)
        if replacingResults {
            searchResults = rankedResults
        } else {
            addUniqueSearchResults(rankedResults)
        }
        searchPage = response.page
        searchTotalPages = response.totalPages
        isSearching = false
    }

    private func fetchNextSearchPageIfNeeded(currentMovie: RemoteMovie) async {
        guard searchResults.last?.id == currentMovie.id else { return }
        guard searchPage < searchTotalPages, !isFetchingSearch else { return }

        isFetchingSearch = true
        let query = searchQuery
        let requestID = activeSearchRequestID
        defer { isFetchingSearch = false }

        do {
            try await searchMovies(query: query, page: searchPage + 1, replacingResults: false, requestID: requestID)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Failed to load more movie results: \(error.localizedDescription)"
        }
    }

    private func addUniqueMovies(_ newMovies: [RemoteMovie]) {
        let unique = newMovies.filter { newMovie in
            !movies.contains(where: { $0.id == newMovie.id })
        }
        movies.append(contentsOf: unique)
    }

    private func addUniqueSearchResults(_ newMovies: [RemoteMovie]) {
        let unique = newMovies.filter { newMovie in
            !searchResults.contains(where: { $0.id == newMovie.id })
        }
        searchResults.append(contentsOf: unique)
    }
}
