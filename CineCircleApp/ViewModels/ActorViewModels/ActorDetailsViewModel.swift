import Foundation

/// Fetches and represents detailed information about a specific actor.
@Observable
@MainActor
class ActorDetailsViewModel {
    private let client: APIClientProtocol

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    /// Actor's date of death.
    var deathday: String?
    /// Actor's date of birth.
    var birthday: String?
    /// Actor biography text.
    var biography: String = ""
    /// Error message if fetching fails.
    var errorMessage: String?

    /// Fetches detailed info for a given actor ID.
    /// - Parameter actorID: The ID of the actor to fetch.
    func fetchActorDetails(for actorID: Int) async {
        do {
            let response: ActorDetails = try await client.fetch(
                path: "person/\(actorID)",
                query: ["language": "EN-US", "page": "1"],
                responseType: ActorDetails.self
            )
            birthday = response.birthday
            biography = response.biography
        } catch {
            errorMessage = "Failded to fetch actor details: \(error.localizedDescription)"
        }
    }
}
