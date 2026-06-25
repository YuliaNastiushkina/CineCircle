import Foundation

/// Fetches and represents detailed information about a specific actor.
@Observable
@MainActor
class ActorDetailsViewModel {
    // MARK: Private interface

    private let client: APIClientProtocol
    private var loadedActorID: Int?
    private var loadingActorID: Int?

    // MARK: Internal interface

    /// Initializes a new instance of `ActorListViewModel`.
    ///
    /// - Parameter client: An object conforming to `APIClientProtocol` used for making API requests.
    ///   Defaults to a shared instance of `APIClient`. This allows for dependency injection,
    ///   particularly useful for testing with a mock API client.
    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    /// Actor's date of death.
    var deathday: String?
    /// Actor's date of birth.
    var birthday: String?
    /// Actor biography text.
    var biography: String = ""
    /// Actor's birth location.
    var placeOfBirth: String?
    /// Alternate names credited to the actor.
    var alsoKnownAs: [String] = []
    /// Actor's official website.
    var homepage: String?
    /// Actor social and external profile IDs.
    var externalIDs: ActorExternalIDs?
    /// Movie and TV credits for this actor.
    var actingCredits: [ActorCredit] = []
    /// Error message if fetching fails.
    var errorMessage: String?

    /// Fetches detailed info for a given actor ID.
    /// - Parameter actorID: The ID of the actor to fetch.
    func fetchActorDetails(for actorID: Int) async {
        guard loadedActorID != actorID, loadingActorID != actorID else { return }

        loadingActorID = actorID
        defer { loadingActorID = nil }

        async let detailsResult: Void = fetchPersonDetails(for: actorID)
        async let externalIDsResult: Void = fetchExternalIDs(for: actorID)
        async let creditsResult: Void = fetchCombinedCredits(for: actorID)

        await detailsResult
        await externalIDsResult
        await creditsResult
        loadedActorID = actorID
    }

    private func fetchPersonDetails(for actorID: Int) async {
        do {
            let response: ActorDetails = try await client.fetch(
                path: "person/\(actorID)",
                query: ["language": "en-US"],
                responseType: ActorDetails.self
            )
            birthday = response.birthday
            deathday = response.deathday
            biography = response.biography
            placeOfBirth = response.placeOfBirth
            alsoKnownAs = response.alsoKnownAs
            homepage = response.homepage
        } catch {
            errorMessage = "Failed to fetch actor details: \(error.localizedDescription)"
        }
    }

    private func fetchExternalIDs(for actorID: Int) async {
        do {
            externalIDs = try await client.fetch(
                path: "person/\(actorID)/external_ids",
                query: [:],
                responseType: ActorExternalIDs.self
            )
        } catch {
            externalIDs = nil
        }
    }

    private func fetchCombinedCredits(for actorID: Int) async {
        do {
            let response: ActorCombinedCreditsResponse = try await client.fetch(
                path: "person/\(actorID)/combined_credits",
                query: ["language": "en-US"],
                responseType: ActorCombinedCreditsResponse.self
            )
            actingCredits = response.cast
                .filter { $0.mediaType == ActorCredit.movieMediaType || $0.mediaType == ActorCredit.tvMediaType }
                .sorted { lhs, rhs in
                    lhs.voteCount == rhs.voteCount
                        ? lhs.voteAverage > rhs.voteAverage
                        : lhs.voteCount > rhs.voteCount
                }
        } catch {
            actingCredits = []
        }
    }
}
