/// Converts a user prompt into normalized movie recommendation intent.
protocol MovieRecommendationServiceProtocol {
    func recommendationIntent(for prompt: String) async throws -> MovieRecommendationIntent
}
