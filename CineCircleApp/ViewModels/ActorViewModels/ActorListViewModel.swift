import Foundation

/// Loads and paginates the list of popular actors.
@Observable
@MainActor
class ActorListViewModel {
    // MARK: Private interface

    private let client: APIClientProtocol
    private(set) var currentPage = 1
    private(set) var totalPages = 1
    private var isFetching = false

    // MARK: Internal interface

    /// List of all fetched actors.
    var actors: [RemoteActor] = []
    /// Error message if fetching fails.
    var errorMessage: String?

    /// Initializes a new instance of `ActorListViewModel`.
    ///
    /// - Parameter client: An object conforming to `APIClientProtocol` used for making API requests.
    ///   Defaults to a shared instance of `APIClient`. This allows for dependency injection,
    ///   particularly useful for testing with a mock API client.
    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    /// Fetches the first page of popular actors from TMDB.
    func fetchPopularActors() async {
        isFetching = true
        defer { isFetching = false }

        do {
            let response: PopularActorsResponse = try await client.fetch(
                path: "person/popular",
                query: ["language": "EN-US", "page": "1"],
                responseType: PopularActorsResponse.self
            )
            actors = response.results
            currentPage = response.page
            totalPages = response.totalPages
        } catch {
            errorMessage = "Failded to fetch actors: \(error.localizedDescription)"
        }
    }

    /// Loads the next page if the user has scrolled to the last item.
    /// - Parameter currentActor: The actor that is currently being rendered.
    func fetchNextPageIfNeeded(currentActor: RemoteActor) async {
        guard let last = actors.last, last.id == currentActor.id else { return }
        guard currentPage < totalPages, !isFetching else { return }

        isFetching = true
        defer { isFetching = false }

        do {
            let response: PopularActorsResponse = try await client.fetch(
                path: "person/popular",
                query: ["language": "en-US", "page": "\(currentPage + 1)"],
                responseType: PopularActorsResponse.self
            )
            actors += response.results
            currentPage = response.page
            totalPages = response.totalPages
        } catch {
            errorMessage = "Failed to load more actors: \(error.localizedDescription)"
        }
    }
}
