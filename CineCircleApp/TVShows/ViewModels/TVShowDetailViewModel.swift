import Foundation

@Observable
@MainActor
final class TVShowDetailViewModel {
    var show: RemoteTVShowDetail?
    var errorMessage: String?

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    /// Fetches full TV show details including credits, videos, and images in a single request.
    /// Images are filtered to English and language-neutral backdrops to reduce near-duplicates.
    func fetchShow(id: Int) async {
        do {
            show = try await client.fetch(
                path: "tv/\(id)",
                query: [
                    "language": "en-US",
                    "append_to_response": "credits,videos,images",
                    "include_image_language": "en,null",
                ],
                responseType: RemoteTVShowDetail.self
            )
        } catch {
            errorMessage = "Failed to load TV show: \(error.localizedDescription)"
        }
    }

    private let client: APIClientProtocol
}
