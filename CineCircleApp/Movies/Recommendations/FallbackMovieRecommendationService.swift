import Foundation

/// Creates basic recommendation intent locally when Gemini is unavailable or skipped.
struct FallbackMovieRecommendationService: MovieRecommendationServiceProtocol {
    func recommendationIntent(for prompt: String) async throws -> MovieRecommendationIntent {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw MovieRecommendationError.emptyPrompt
        }

        let genres = genres(in: trimmedPrompt)
        let moods = moods(in: trimmedPrompt)
        let themes = themes(in: trimmedPrompt)

        return MovieRecommendationIntent(
            genres: genres,
            moods: moods,
            themes: themes,
            searchQueries: searchQueries(prompt: trimmedPrompt, genres: genres, moods: moods, themes: themes),
            mustMatchConcepts: mustMatchConcepts(from: themes),
            shouldMatchConcepts: shouldMatchConcepts(from: themes, moods: moods),
            keywordProbes: keywordProbes(from: themes),
            explanation: "Showing movie matches based on your prompt.",
            fallbackPrompt: trimmedPrompt
        )
    }

    private func genres(in prompt: String) -> [MoviesGenre] {
        let text = prompt.normalizedForRecommendationMatching
        var genres: [MoviesGenre] = []

        append(.family, to: &genres, when: text.containsAny(["family", "kids", "children", "christmas", "holiday", "santa"]))
        append(.fantasy, to: &genres, when: text.containsAny(["christmas", "holiday", "santa", "magic", "fantasy"]))
        append(.comedy, to: &genres, when: text.containsAny(["comedy", "funny", "feel good", "feelgood", "feel better", "comfort", "uplifting", "happy", "christmas", "holiday"]))
        append(.adventure, to: &genres, when: text.containsAny(["pirate", "treasure", "adventure", "quest", "hunt", "journey"]))
        append(.romance, to: &genres, when: text.containsAny(["breakup", "love", "romance", "romantic", "relationship", "heartbreak"]))
        append(.horror, to: &genres, when: text.containsAny(["scary", "horror", "ghost", "haunted", "creepy"]))
        append(.mystery, to: &genres, when: text.containsAny(["mystery", "detective", "investigation", "crime", "clue"]))
        append(.scienceFiction, to: &genres, when: text.containsAny(["sci fi", "sci-fi", "science fiction", "space", "future", "alien"]))
        append(.animation, to: &genres, when: text.containsAny(["animated", "animation", "cartoon", "anime", "kids"]))

        return genres
    }

    private func moods(in prompt: String) -> [String] {
        let text = prompt.normalizedForRecommendationMatching
        var moods: [String] = []

        append("funny", to: &moods, when: text.containsAny(["comedy", "funny", "laugh"]))
        append("comforting", to: &moods, when: text.containsAny(["feel better", "breakup", "comfort", "uplifting", "happy", "family"]))
        append("festive", to: &moods, when: text.containsAny(["christmas", "holiday", "santa", "xmas"]))
        append("warm", to: &moods, when: text.containsAny(["christmas", "holiday", "family", "cozy", "warm"]))
        append("dark", to: &moods, when: text.containsAny(["dark", "grim", "intense"]))
        append("scary", to: &moods, when: text.containsAny(["scary", "horror", "creepy"]))
        append("romantic", to: &moods, when: text.containsAny(["romance", "romantic", "love"]))

        return moods
    }

    private func themes(in prompt: String) -> [String] {
        let text = prompt.normalizedForRecommendationMatching
        var themes: [String] = []

        append("christmas", to: &themes, when: text.containsAny(["christmas", "xmas", "santa"]))
        append("holiday", to: &themes, when: text.containsAny(["christmas", "holiday", "holidays", "xmas", "santa"]))
        append("family", to: &themes, when: text.containsAny(["family", "kids", "children"]))
        append("pirates", to: &themes, when: text.contains("pirate"))
        append("treasure hunt", to: &themes, when: text.containsAny(["treasure", "hunt"]))
        append("breakup recovery", to: &themes, when: text.containsAny(["breakup", "heartbreak", "feel better"]))
        append("space", to: &themes, when: text.contains("space"))
        append("detective", to: &themes, when: text.containsAny(["detective", "investigation"]))

        return themes
    }

    private func mustMatchConcepts(from themes: [String]) -> [String] {
        themes.filter { ["christmas", "holiday", "pirates", "treasure hunt", "breakup recovery"].contains($0) }
    }

    private func shouldMatchConcepts(from themes: [String], moods: [String]) -> [String] {
        themes + moods
    }

    private func keywordProbes(from themes: [String]) -> [String] {
        var probes: [String] = []
        appendKeywordProbes(from: themes, to: &probes)
        return probes
    }

    private func appendKeywordProbes(from themes: [String], to probes: inout [String]) {
        for theme in themes {
            switch theme {
            case "christmas", "holiday":
                append("christmas", to: &probes, when: true)
                append("christmas eve", to: &probes, when: true)
                append("santa claus", to: &probes, when: true)
                append("holiday", to: &probes, when: true)
            case "pirates":
                append("pirate", to: &probes, when: true)
                append("pirates", to: &probes, when: true)
            case "treasure hunt":
                append("treasure hunt", to: &probes, when: true)
                append("hidden treasure", to: &probes, when: true)
                append("treasure map", to: &probes, when: true)
            default:
                append(theme, to: &probes, when: true)
            }
        }
    }

    private func searchQueries(prompt: String, genres: [MoviesGenre], moods: [String], themes: [String]) -> [String] {
        var queries: [String] = []

        append("christmas family comedy", to: &queries, when: themes.contains("christmas") && themes.contains("family"))
        append("holiday family movie", to: &queries, when: themes.contains("holiday") && themes.contains("family"))
        append("christmas family fantasy", to: &queries, when: themes.contains("christmas") && genres.contains(.fantasy))
        append("classic christmas family movie", to: &queries, when: themes.contains("christmas") && themes.contains("family"))
        append("pirate treasure comedy", to: &queries, when: themes.contains("pirates") && genres.contains(.comedy))
        append("pirate treasure adventure", to: &queries, when: themes.contains("pirates"))
        append("treasure hunt adventure", to: &queries, when: themes.contains("treasure hunt"))
        append("uplifting romantic comedy", to: &queries, when: themes.contains("breakup recovery"))
        append("heartwarming comedy", to: &queries, when: moods.contains("comforting"))
        append("breakup recovery romance", to: &queries, when: themes.contains("breakup recovery"))

        let genreQuery = genres.map(\.displayName).joined(separator: " ").lowercased()
        if !genreQuery.isEmpty, let theme = themes.first {
            append("\(theme) \(genreQuery)", to: &queries, when: true)
        }

        append(prompt, to: &queries, when: true)
        return queries
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
