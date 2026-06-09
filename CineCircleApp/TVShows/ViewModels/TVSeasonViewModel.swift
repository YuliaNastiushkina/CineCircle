import Foundation

@Observable
@MainActor
final class TVSeasonViewModel {
    var episodes: [RemoteTVEpisode] = []
    var errorMessage: String?
    private(set) var isLoading = false

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    func fetchSeason(showID: Int, seasonNumber: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: RemoteTVSeasonDetail = try await client.fetch(
                path: "tv/\(showID)/season/\(seasonNumber)",
                query: ["language": "en-US"],
                responseType: RemoteTVSeasonDetail.self
            )
            episodes = response.episodes
        } catch {
            episodes = []
            errorMessage = "Failed to load episodes: \(error.localizedDescription)"
        }
    }

    private let client: APIClientProtocol
}
