import Foundation

/// Scores TMDB movies against recommendation intent so the best local matches appear first.
struct MovieRecommendationScorer {
    func score(_ movie: RemoteMovie, intent: MovieRecommendationIntent, appearanceCount: Int) -> Double {
        var score = 0.0

        let requestedGenreIDs = Set(intent.genres.map(\.id))
        let matchingGenreCount = Set(movie.genreIDs).intersection(requestedGenreIDs).count
        score += Double(matchingGenreCount) * 40

        let searchableTitle = movie.title.normalizedForRecommendationScoring
        let searchableOverview = movie.overview.normalizedForRecommendationScoring
        let matchTerms = normalizedMatchTerms(from: intent)

        if containsAny(matchTerms, in: searchableTitle) {
            score += 25
        }

        if containsAny(matchTerms, in: searchableOverview) {
            score += 25
        }

        if appearanceCount > 1 {
            score += Double(appearanceCount - 1) * 15
        }

        if movie.posterPath != nil {
            score += 10
        }

        if !movie.overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            score += 10
        }

        score += min(max(movie.voteAverage, 0) / 10 * 15, 15)
        score += min(log10(Double(max(movie.voteCount, 0)) + 1) * 5, 15)

        if movie.voteCount < 20 {
            score -= 20
        }

        return score
    }

    private func normalizedMatchTerms(from intent: MovieRecommendationIntent) -> [String] {
        let values = intent.themes + intent.searchQueries + intent.moods
        var seen = Set<String>()
        return values.flatMap { value in
            value.recommendationMatchTerms
        }.filter { term in
            seen.insert(term).inserted
        }
    }

    private func containsAny(_ terms: [String], in text: String) -> Bool {
        terms.contains { text.contains($0) }
    }
}

private extension String {
    var normalizedForRecommendationScoring: String {
        lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var recommendationMatchTerms: [String] {
        let phrase = normalizedForRecommendationScoring
        guard !phrase.isEmpty else { return [] }

        let words = phrase
            .components(separatedBy: .whitespaces)
            .filter { $0.count >= 4 }

        return ([phrase] + words).filter { !$0.isEmpty }
    }
}
