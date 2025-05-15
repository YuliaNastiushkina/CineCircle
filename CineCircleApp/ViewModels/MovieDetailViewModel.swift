import Foundation

/// Responsible for managing and loading the details of a particular movie.
/// It fetches data from the API and exposes it to the view layer.
@MainActor
@Observable
class MovieDetailViewModel {
    /// A list of actors playing in the movie.
    var cast: [MovieCast] = []
    /// The name of the movie's director.
    var director: String?
    /// The name of the movie's producer.
    var producer: String?
    /// An error message to be displayed if fetching fails.
    var errorMessage: String?

    /// Fetches cast and crew details for the specified movie.
    ///
    /// If the request is successful, `cast`, `director`, and `producer` will be updated.
    /// If the request fails, `errorMessage` will be set.
    /// - Parameter movieId: The ID of the movie for which details are requested.
    func fetchCastAndCrew(for movieId: Int) async {
        do {
            let response: MovieCreditsResponse = try await client.fetch(
                path: "movie/\(movieId)/credits",
                responseType: MovieCreditsResponse.self
            )
            cast = response.cast
            director = response.crew.first(where: { $0.job == "Director" })?.name
            producer = response.crew.first(where: { $0.job == "Producer" })?.name
        } catch {
            errorMessage = "Failded to fetch cast: \(error.localizedDescription)"
        }
    }

    // MARK: Private interface

    private let client = APIClient()
}
