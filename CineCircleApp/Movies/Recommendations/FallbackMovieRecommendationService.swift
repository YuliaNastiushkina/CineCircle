import Foundation

/// Creates basic recommendation intent locally when Gemini is unavailable or skipped.
struct FallbackMovieRecommendationService: MovieRecommendationServiceProtocol {
    func recommendationIntent(for prompt: String) async throws -> MovieRecommendationIntent {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw MovieRecommendationError.emptyPrompt
        }

        return MovieRecommendationIntent(
            genres: genres(in: trimmedPrompt),
            moods: moods(in: trimmedPrompt),
            themes: themes(in: trimmedPrompt),
            searchQueries: [trimmedPrompt],
            explanation: "Showing movie matches based on your prompt.",
            fallbackPrompt: trimmedPrompt
        )
    }

    private func genres(in prompt: String) -> [MoviesGenre] {
        let text = prompt.normalizedForRecommendationMatching
        var genres: [MoviesGenre] = []

        append(.comedy, to: &genres, when: text.containsAny(["comedy", "funny", "feel good", "feelgood", "feel better", "comfort", "uplifting", "happy"]))
        append(.adventure, to: &genres, when: text.containsAny(["pirate", "treasure", "adventure", "quest", "hunt", "journey"]))
        append(.romance, to: &genres, when: text.containsAny(["breakup", "love", "romance", "romantic", "relationship", "heartbreak"]))
        append(.horror, to: &genres, when: text.containsAny(["scary", "horror", "ghost", "haunted", "creepy"]))
        append(.mystery, to: &genres, when: text.containsAny(["mystery", "detective", "investigation", "crime", "clue"]))
        append(.scienceFiction, to: &genres, when: text.containsAny(["sci fi", "sci-fi", "science fiction", "space", "future", "alien"]))

        return genres
    }

    private func moods(in prompt: String) -> [String] {
        let text = prompt.normalizedForRecommendationMatching
        var moods: [String] = []

        append("funny", to: &moods, when: text.containsAny(["comedy", "funny", "laugh"]))
        append("comforting", to: &moods, when: text.containsAny(["feel better", "breakup", "comfort", "uplifting", "happy"]))
        append("dark", to: &moods, when: text.containsAny(["dark", "grim", "intense"]))
        append("scary", to: &moods, when: text.containsAny(["scary", "horror", "creepy"]))
        append("romantic", to: &moods, when: text.containsAny(["romance", "romantic", "love"]))

        return moods
    }

    private func themes(in prompt: String) -> [String] {
        let text = prompt.normalizedForRecommendationMatching
        var themes: [String] = []

        append("pirates", to: &themes, when: text.contains("pirate"))
        append("treasure hunt", to: &themes, when: text.containsAny(["treasure", "hunt"]))
        append("breakup recovery", to: &themes, when: text.containsAny(["breakup", "heartbreak", "feel better"]))
        append("space", to: &themes, when: text.contains("space"))
        append("detective", to: &themes, when: text.containsAny(["detective", "investigation"]))
        append("family", to: &themes, when: text.contains("family"))

        return themes
    }

    private func append<T: Equatable>(_ value: T, to values: inout [T], when condition: Bool) {
        guard condition, !values.contains(value) else { return }
        values.append(value)
    }
}

private extension String {
    var normalizedForRecommendationMatching: String {
        lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func containsAny(_ values: [String]) -> Bool {
        values.contains { contains($0) }
    }
}
