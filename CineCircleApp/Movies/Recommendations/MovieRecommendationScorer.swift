import Foundation

/// Scores TMDB movies against recommendation intent so the best local matches appear first.
struct MovieRecommendationScorer {
    func score(_ movie: RemoteMovie, intent: MovieRecommendationIntent, appearanceCount: Int) -> Double {
        var score = 0.0

        let requestedGenreIDs = Set(intent.genres.map(\.id))
        let matchingGenreCount = Set(movie.genreIDs).intersection(requestedGenreIDs).count
        score += Double(matchingGenreCount) * 36

        if !requestedGenreIDs.isEmpty, matchingGenreCount == requestedGenreIDs.count {
            score += 10
        }

        score += softGenreConstraintScore(movie, intent: intent)

        let searchableTitle = movie.title.normalizedForRecommendationScoring
        let searchableOverview = movie.overview.normalizedForRecommendationScoring
        let weightedTerms = weightedMatchTerms(from: intent)

        score += conceptCoverageScore(for: intent, title: searchableTitle, overview: searchableOverview)
        score += cappedTextScore(weightedTerms, in: searchableTitle, using: \.titleWeight, cap: 75)
        score += cappedTextScore(weightedTerms, in: searchableOverview, using: \.overviewWeight, cap: 85)
        score += semanticFitScore(for: movie, intent: intent, title: searchableTitle, overview: searchableOverview)
        score += moodAlignmentScore(for: intent, title: searchableTitle, overview: searchableOverview)

        if appearanceCount > 1 {
            score += Double(appearanceCount - 1) * 18
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

    private func softGenreConstraintScore(_ movie: RemoteMovie, intent: MovieRecommendationIntent) -> Double {
        var score = 0.0
        let movieGenreIDs = Set(movie.genreIDs)
        let excludedGenreIDs = Set(intent.excludedGenres.map(\.id))

        score -= Double(movieGenreIDs.intersection(excludedGenreIDs).count) * 22

        if movieGenreIDs.contains(MoviesGenre.animation.id) {
            switch intent.formatPreference {
            case .liveActionPreferred:
                score -= 30
            case .animatedPreferred:
                score += 22
            case .any:
                break
            }
        }

        return score
    }

    private func weightedMatchTerms(from intent: MovieRecommendationIntent) -> [WeightedMatchTerm] {
        var terms: [WeightedMatchTerm] = []
        var seen = Set<String>()

        appendTerms(from: expandedConceptTerms(intent.mustMatchConcepts), titleWeight: 32, overviewWeight: 30, to: &terms, seen: &seen)
        appendTerms(from: expandedConceptTerms(intent.requiredThemes), titleWeight: 28, overviewWeight: 26, to: &terms, seen: &seen)
        appendTerms(from: expandedConceptTerms(intent.shouldMatchConcepts), titleWeight: 18, overviewWeight: 18, to: &terms, seen: &seen)
        appendTerms(from: expandedConceptTerms(intent.preferredThemes), titleWeight: 14, overviewWeight: 14, to: &terms, seen: &seen)
        appendTerms(from: intent.searchQueries, titleWeight: 16, overviewWeight: 12, to: &terms, seen: &seen)
        appendTerms(from: expandedMoodTerms(from: intent.moods), titleWeight: 10, overviewWeight: 14, to: &terms, seen: &seen)

        return terms
    }

    private func appendTerms(
        from values: [String],
        titleWeight: Double,
        overviewWeight: Double,
        to terms: inout [WeightedMatchTerm],
        seen: inout Set<String>
    ) {
        for value in values {
            let phrase = value.normalizedForRecommendationScoring
            guard !phrase.isEmpty else { continue }
            appendTerm(phrase, titleWeight: titleWeight, overviewWeight: overviewWeight, to: &terms, seen: &seen)

            for word in phrase.recommendationMatchWords {
                appendTerm(
                    word,
                    titleWeight: titleWeight * 0.45,
                    overviewWeight: overviewWeight * 0.35,
                    to: &terms,
                    seen: &seen
                )
            }
        }
    }

    private func appendTerm(
        _ value: String,
        titleWeight: Double,
        overviewWeight: Double,
        to terms: inout [WeightedMatchTerm],
        seen: inout Set<String>
    ) {
        guard seen.insert(value).inserted else { return }
        terms.append(WeightedMatchTerm(value: value, titleWeight: titleWeight, overviewWeight: overviewWeight))
    }

    private func cappedTextScore(
        _ terms: [WeightedMatchTerm],
        in text: String,
        using weight: KeyPath<WeightedMatchTerm, Double>,
        cap: Double
    ) -> Double {
        let score = terms.reduce(0.0) { partial, term in
            guard text.contains(term.value) else { return partial }
            return partial + term[keyPath: weight]
        }
        return min(score, cap)
    }

    private func conceptCoverageScore(for intent: MovieRecommendationIntent, title: String, overview: String) -> Double {
        let combinedText = title + " " + overview
        var score = 0.0

        for concept in intent.mustMatchConcepts {
            let terms = expandedConceptTerms([concept]).map(\.normalizedForRecommendationScoring)
            guard !terms.isEmpty else { continue }

            if title.containsAny(terms) {
                score += 42
            } else if overview.containsAny(terms) {
                score += 34
            } else {
                score -= 38
            }
        }

        for concept in intent.shouldMatchConcepts {
            let terms = expandedConceptTerms([concept]).map(\.normalizedForRecommendationScoring)
            guard !terms.isEmpty else { continue }

            if title.containsAny(terms) {
                score += 18
            } else if overview.containsAny(terms) {
                score += 14
            }
        }

        for concept in intent.avoidConcepts {
            let terms = expandedConceptTerms([concept]).map(\.normalizedForRecommendationScoring)
            guard !terms.isEmpty else { continue }

            if combinedText.containsAny(terms) {
                score -= 46
            }
        }

        return score
    }

    private func semanticFitScore(for movie: RemoteMovie, intent: MovieRecommendationIntent, title: String, overview: String) -> Double {
        let combinedText = title + " " + overview
        let movieGenreIDs = Set(movie.genreIDs)
        var score = 0.0

        if intent.matchesConcept(["christmas", "holiday"]) {
            let hasHolidaySignal = combinedText.containsAny(Self.holidaySignals)

            if hasHolidaySignal {
                score += 44

                if movieGenreIDs.contains(MoviesGenre.family.id) {
                    score += 26
                }

                if movieGenreIDs.contains(MoviesGenre.comedy.id) || movieGenreIDs.contains(MoviesGenre.fantasy.id) {
                    score += 12
                }
            } else {
                score -= 54
            }
        }

        if intent.matchesConcept(["pirates", "treasure hunt", "hidden treasure", "treasure map"]) {
            if combinedText.containsAny(["pirate", "pirates", "treasure", "artifact", "relic", "ship", "sea", "island", "map", "clue", "hidden", "ancient"]) {
                score += 42
            }

            if movieGenreIDs.contains(MoviesGenre.adventure.id) {
                score += 18
            }
        }

        return score
    }

    private static let holidaySignals = ["christmas", "holiday", "holidays", "santa", "xmas", "noel", "christmas eve"]

    private func expandedConceptTerms(_ concepts: [String]) -> [String] {
        concepts.flatMap { concept in
            switch concept.normalizedForRecommendationScoring {
            case "christmas", "holiday", "holidays", "xmas":
                ["christmas", "holiday", "santa", "xmas", "noel", "christmas eve"]
            case "treasure hunt", "hidden treasure", "lost treasure", "treasure map":
                ["treasure", "treasure hunt", "hidden treasure", "lost treasure", "treasure map", "artifact", "relic", "map", "clue"]
            case "pirates", "pirate":
                ["pirate", "pirates", "ship", "sea", "island"]
            case "family":
                ["family", "families", "parents", "children"]
            case "animation", "cartoon":
                ["animation", "animated", "cartoon"]
            case "sad ending", "tragedy", "tragic":
                ["sad", "tragic", "tragedy", "devastating", "bleak"]
            default:
                [concept]
            }
        }
    }

    private func expandedMoodTerms(from moods: [String]) -> [String] {
        moods.flatMap { mood in
            switch mood.normalizedForRecommendationScoring {
            case "comforting", "uplifting", "feel good", "feel better", "hopeful":
                ["comforting", "uplifting", "feel good", "heartwarming", "hopeful", "lighthearted"]
            case "festive", "warm", "cozy":
                ["festive", "warm", "cozy", "holiday", "christmas", "heartwarming"]
            case "funny", "comedy", "playful":
                ["funny", "comedy", "playful", "lighthearted", "humorous"]
            case "romantic", "romance":
                ["romantic", "romance", "love", "relationship"]
            case "dark", "grim", "intense":
                ["dark", "grim", "intense", "bleak", "psychological"]
            case "scary", "horror", "creepy":
                ["scary", "horror", "creepy", "haunted", "terrifying"]
            default:
                [mood]
            }
        }
    }

    private func moodAlignmentScore(for intent: MovieRecommendationIntent, title: String, overview: String) -> Double {
        let combinedText = title + " " + overview
        let normalizedMoods = Set(intent.moods.map(\.normalizedForRecommendationScoring))
        var score = 0.0

        if normalizedMoods.contains("comforting") || normalizedMoods.contains("uplifting") || normalizedMoods.contains("feel good") {
            if combinedText.containsAny(["heartwarming", "uplifting", "hopeful", "feel good", "lighthearted"]) {
                score += 18
            }

            if combinedText.containsAny(["brutal", "bleak", "disturbing", "tragic", "devastating"]) {
                score -= 18
            }
        }

        if normalizedMoods.contains("festive") || normalizedMoods.contains("warm") || normalizedMoods.contains("cozy") {
            if combinedText.containsAny(["christmas", "holiday", "festive", "santa", "heartwarming", "family"]) {
                score += 18
            }
        }

        return score
    }
}

private struct WeightedMatchTerm {
    let value: String
    let titleWeight: Double
    let overviewWeight: Double
}

private extension MovieRecommendationIntent {
    func matchesConcept(_ concepts: [String]) -> Bool {
        mustMatchConcepts.containsNormalizedAny(concepts)
            || shouldMatchConcepts.containsNormalizedAny(concepts)
            || requiredThemes.containsNormalizedAny(concepts)
            || themes.containsNormalizedAny(concepts)
    }
}

private extension [String] {
    func containsNormalizedAny(_ values: [String]) -> Bool {
        let normalizedValues = Set(values.map(\.normalizedForRecommendationScoring))
        return contains { normalizedValues.contains($0.normalizedForRecommendationScoring) }
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

    var recommendationMatchWords: [String] {
        let stopWords: Set<String> = ["with", "that", "this", "movie", "movies", "film", "films", "something", "about", "after", "before", "want"]
        return components(separatedBy: .whitespaces)
            .filter { $0.count >= 4 && !stopWords.contains($0) }
    }

    func containsAny(_ values: [String]) -> Bool {
        values.contains { contains($0) }
    }
}
