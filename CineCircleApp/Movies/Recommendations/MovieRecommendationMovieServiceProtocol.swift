/// Fetches and ranks real TMDB movies for a normalized recommendation intent.
protocol MovieRecommendationMovieServiceProtocol {
    func rankedMovies(for intent: MovieRecommendationIntent) async throws -> [RemoteMovie]
}
