import Foundation

@Observable
@MainActor
final class TVShowDetailViewModel {
    var show: RemoteTVShowDetail?
    var errorMessage: String?

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    func fetchShow(id: Int) async {
        do {
            show = try await client.fetch(
                path: "tv/\(id)",
                query: ["language": "en-US"],
                responseType: RemoteTVShowDetail.self
            )
        } catch {
            errorMessage = "Failed to load TV show: \(error.localizedDescription)"
        }
    }

    private let client: APIClientProtocol
}
