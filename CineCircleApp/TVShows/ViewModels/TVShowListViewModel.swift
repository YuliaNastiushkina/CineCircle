import Foundation

enum TVShowListFilter: Equatable {
    case all
    case popular
    case genre(TVGenre)
}

@Observable
@MainActor
final class TVShowListViewModel {
    var shows: [RemoteTVShow] = []
    var searchResults: [RemoteTVShow] = []
    var searchText = ""
    var errorMessage: String?
    var isSorted = false
    var showSavedOnly = false
    var savedIDs: Set<Int> = []
    var selectedFilter: TVShowListFilter = .all
    private(set) var isLoading = false
    private(set) var isSearching = false
    private(set) var currentPage = 1
    private(set) var totalPages = 1

    var displayedShows: [RemoteTVShow] {
        let query = searchQuery
        let savedShows = showSavedOnly ? shows.filter { savedIDs.contains($0.id) } : shows
        let baseShows: [RemoteTVShow] = if query.isEmpty {
            savedShows
        } else if showSavedOnly {
            savedShows.filter { FuzzyMatch.matches($0.name, query: query) }
        } else {
            searchResults
        }

        let sorted = isSorted
            ? baseShows.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            : baseShows
        return sorted
    }

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    func fetchAllShows() async {
        await selectFilter(.all)
    }

    func fetchPopularShows() async {
        await selectFilter(.popular)
    }

    func selectFilter(_ filter: TVShowListFilter) async {
        selectedFilter = filter
        shows = []
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
            guard activeRequestID == requestID, selectedFilter == filter else { return }
            shows = response.results
            currentPage = response.page
            totalPages = response.totalPages
        } catch is CancellationError {
            return
        } catch {
            guard activeRequestID == requestID else { return }
            errorMessage = "Failed to load TV shows: \(error.localizedDescription)"
        }
    }

    func scheduleSearch() {
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
                try await searchShows(query: query, page: 1, replacingResults: true, requestID: requestID)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, activeSearchRequestID == requestID else { return }
                searchResults = []
                searchPage = 1
                searchTotalPages = 1
                errorMessage = "Failed to search TV shows: \(error.localizedDescription)"
                isSearching = false
            }
        }
    }

    func fetchNextPageIfNeeded(currentShow: RemoteTVShow) async {
        if !searchQuery.isEmpty, !showSavedOnly {
            await fetchNextSearchPageIfNeeded(currentShow: currentShow)
            return
        }

        guard shows.last?.id == currentShow.id else { return }
        guard currentPage < totalPages, !isFetching else { return }

        isFetching = true
        let filter = selectedFilter
        let requestID = activeRequestID
        defer { isFetching = false }

        do {
            let response = try await fetchPage(currentPage + 1, filter: filter)
            guard activeRequestID == requestID, selectedFilter == filter else { return }
            addUniqueShows(response.results)
            currentPage = response.page
            totalPages = response.totalPages
        } catch is CancellationError {
            return
        } catch {
            guard activeRequestID == requestID else { return }
            errorMessage = "Failed to load more TV shows: \(error.localizedDescription)"
        }
    }

    private let client: APIClientProtocol
    private var isFetching = false
    private var activeRequestID = UUID()
    private var searchTask: Task<Void, Never>?
    private var activeSearchRequestID = UUID()
    private var searchPage = 1
    private var searchTotalPages = 1
    private var isFetchingSearch = false

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fetchPage(_ page: Int, filter: TVShowListFilter) async throws -> TVShowResponse {
        var query = ["language": "en-US", "page": "\(page)"]
        let path: String

        switch filter {
        case .popular:
            path = "tv/popular"
        case .all:
            path = "discover/tv"
            query["sort_by"] = "popularity.desc"
        case let .genre(genre):
            path = "discover/tv"
            query["sort_by"] = "popularity.desc"
            query["with_genres"] = "\(genre.id)"
        }

        return try await client.fetch(path: path, query: query, responseType: TVShowResponse.self)
    }

    private func searchShows(query: String, page: Int, replacingResults: Bool, requestID: UUID) async throws {
        let response: TVShowResponse = try await client.fetch(
            path: "search/tv",
            query: [
                "language": "en-US",
                "page": "\(page)",
                "query": query,
            ],
            responseType: TVShowResponse.self
        )

        guard activeSearchRequestID == requestID, query == searchQuery else { return }

        let rankedResults = FuzzyMatch.ranked(response.results, query: query, text: \.name)
        if replacingResults {
            searchResults = rankedResults
        } else {
            addUniqueSearchResults(rankedResults)
        }
        searchPage = response.page
        searchTotalPages = response.totalPages
        isSearching = false
    }

    private func fetchNextSearchPageIfNeeded(currentShow: RemoteTVShow) async {
        guard searchResults.last?.id == currentShow.id else { return }
        guard searchPage < searchTotalPages, !isFetchingSearch else { return }

        isFetchingSearch = true
        let query = searchQuery
        let requestID = activeSearchRequestID
        defer { isFetchingSearch = false }

        do {
            try await searchShows(query: query, page: searchPage + 1, replacingResults: false, requestID: requestID)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Failed to load more TV show results: \(error.localizedDescription)"
        }
    }

    private func addUniqueShows(_ newShows: [RemoteTVShow]) {
        let uniqueShows = newShows.filter { newShow in
            !shows.contains(where: { $0.id == newShow.id })
        }
        shows.append(contentsOf: uniqueShows)
    }

    private func addUniqueSearchResults(_ newShows: [RemoteTVShow]) {
        let uniqueShows = newShows.filter { newShow in
            !searchResults.contains(where: { $0.id == newShow.id })
        }
        searchResults.append(contentsOf: uniqueShows)
    }
}
