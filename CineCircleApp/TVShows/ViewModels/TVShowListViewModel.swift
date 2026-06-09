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
    var searchText = ""
    var errorMessage: String?
    var isSorted = false
    var showSavedOnly = false
    var savedIDs: Set<Int> = []
    var selectedFilter: TVShowListFilter = .all
    private(set) var isLoading = false
    private(set) var currentPage = 1
    private(set) var totalPages = 1

    var displayedShows: [RemoteTVShow] {
        let searched = searchText.isEmpty
            ? shows
            : shows.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        let sorted = isSorted
            ? searched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            : searched
        return showSavedOnly ? sorted.filter { savedIDs.contains($0.id) } : sorted
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
        defer { isLoading = false }

        do {
            let response = try await fetchPage(1, filter: filter)
            guard selectedFilter == filter else { return }
            shows = response.results
            currentPage = response.page
            totalPages = response.totalPages
        } catch {
            errorMessage = "Failed to load TV shows: \(error.localizedDescription)"
        }
    }

    func fetchNextPageIfNeeded(currentShow: RemoteTVShow) async {
        guard shows.last?.id == currentShow.id else { return }
        guard currentPage < totalPages, !isFetching else { return }

        isFetching = true
        let filter = selectedFilter
        defer { isFetching = false }

        do {
            let response = try await fetchPage(currentPage + 1, filter: filter)
            guard selectedFilter == filter else { return }
            let uniqueShows = response.results.filter { newShow in
                !shows.contains(where: { $0.id == newShow.id })
            }
            shows.append(contentsOf: uniqueShows)
            currentPage = response.page
            totalPages = response.totalPages
        } catch {
            errorMessage = "Failed to load more TV shows: \(error.localizedDescription)"
        }
    }

    private let client: APIClientProtocol
    private var isFetching = false

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
}
