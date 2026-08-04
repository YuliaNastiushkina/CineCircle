import Foundation

extension MoviesGenre: Codable {}

enum MovieFormatPreference: String, Codable, Sendable {
    case any
    case liveActionPreferred
    case animatedPreferred
}

/// Structured search plan produced from a user's natural-language movie prompt.
///
/// The app uses this value to query and rank real TMDB movies; it should not contain
/// model-selected movie titles or any user profile data.
struct MovieRecommendationIntent: Equatable, Sendable {
    static let maxGenres = 4
    static let maxExcludedGenres = 4
    static let maxMoods = 5
    static let maxThemes = 8
    static let maxRequiredThemes = 4
    static let maxPreferredThemes = 8
    static let maxSearchQueries = 6
    static let maxConcepts = 8
    static let maxKeywordProbes = 10

    let genres: [MoviesGenre]
    let excludedGenres: [MoviesGenre]
    let moods: [String]
    let themes: [String]
    let requiredThemes: [String]
    let preferredThemes: [String]
    let searchQueries: [String]
    let mustMatchConcepts: [String]
    let shouldMatchConcepts: [String]
    let avoidConcepts: [String]
    let keywordProbes: [String]
    let runtimeMin: Int?
    let runtimeMax: Int?
    let releaseYearMin: Int?
    let releaseYearMax: Int?
    let language: String?
    let formatPreference: MovieFormatPreference
    let explanation: String?

    init(
        genres: [MoviesGenre] = [],
        excludedGenres: [MoviesGenre] = [],
        moods: [String] = [],
        themes: [String] = [],
        requiredThemes: [String] = [],
        preferredThemes: [String] = [],
        searchQueries: [String] = [],
        mustMatchConcepts: [String] = [],
        shouldMatchConcepts: [String] = [],
        avoidConcepts: [String] = [],
        keywordProbes: [String] = [],
        runtimeMin: Int? = nil,
        runtimeMax: Int? = nil,
        releaseYearMin: Int? = nil,
        releaseYearMax: Int? = nil,
        language: String? = nil,
        formatPreference: MovieFormatPreference = .any,
        explanation: String? = nil,
        fallbackPrompt: String? = nil
    ) {
        var normalizedGenres = Array(Self.unique(genres).prefix(Self.maxGenres))
        var normalizedExcludedGenres = Array(Self.unique(excludedGenres).prefix(Self.maxExcludedGenres))
        var normalizedMoods = Self.normalizedStrings(moods, limit: Self.maxMoods)
        var normalizedThemes = Self.normalizedStrings(themes, limit: Self.maxThemes)
        var normalizedRequiredThemes = Self.normalizedStrings(requiredThemes, limit: Self.maxRequiredThemes)
        var normalizedPreferredThemes = Self.normalizedStrings(preferredThemes, limit: Self.maxPreferredThemes)
        var normalizedSearchQueries = searchQueries
        var normalizedMustMatchConcepts = Self.normalizedStrings(mustMatchConcepts + requiredThemes, limit: Self.maxConcepts)
        var normalizedShouldMatchConcepts = Self.normalizedStrings(shouldMatchConcepts + preferredThemes + themes + moods, limit: Self.maxConcepts)
        var normalizedAvoidConcepts = Self.normalizedStrings(avoidConcepts, limit: Self.maxConcepts)
        var normalizedKeywordProbes = Self.normalizedStrings(keywordProbes + requiredThemes + themes + preferredThemes, limit: Self.maxKeywordProbes)
        var normalizedFormatPreference = formatPreference

        if let fallbackPrompt {
            let refinement = PromptIntentRefinement(prompt: fallbackPrompt)
            normalizedGenres = Self.merged(normalizedGenres, refinement.genres, limit: Self.maxGenres)
            normalizedExcludedGenres = Self.merged(normalizedExcludedGenres, refinement.excludedGenres, limit: Self.maxExcludedGenres)
            normalizedMoods = Self.merged(normalizedMoods, refinement.moods, limit: Self.maxMoods)
            normalizedThemes = Self.merged(normalizedThemes, refinement.themes, limit: Self.maxThemes)
            normalizedRequiredThemes = Self.merged(normalizedRequiredThemes, refinement.requiredThemes, limit: Self.maxRequiredThemes)
            normalizedPreferredThemes = Self.merged(normalizedPreferredThemes, refinement.preferredThemes, limit: Self.maxPreferredThemes)
            normalizedSearchQueries = refinement.searchQueries + normalizedSearchQueries
            normalizedMustMatchConcepts = Self.merged(normalizedMustMatchConcepts, refinement.requiredThemes, limit: Self.maxConcepts)
            normalizedShouldMatchConcepts = Self.merged(normalizedShouldMatchConcepts, refinement.preferredThemes + refinement.themes + refinement.moods, limit: Self.maxConcepts)
            normalizedAvoidConcepts = Self.merged(normalizedAvoidConcepts, refinement.avoidConcepts, limit: Self.maxConcepts)
            normalizedKeywordProbes = Self.merged(normalizedKeywordProbes, refinement.keywordProbes + refinement.requiredThemes + refinement.themes, limit: Self.maxKeywordProbes)

            if normalizedFormatPreference == .any {
                normalizedFormatPreference = refinement.formatPreference
            }
        }

        if normalizedSearchQueries.isEmpty, let fallbackPrompt {
            normalizedSearchQueries.append(fallbackPrompt)
        }

        self.genres = normalizedGenres
        self.excludedGenres = normalizedExcludedGenres
        self.moods = normalizedMoods
        self.themes = normalizedThemes
        self.requiredThemes = normalizedRequiredThemes
        self.preferredThemes = normalizedPreferredThemes
        self.searchQueries = Self.normalizedStrings(normalizedSearchQueries, limit: Self.maxSearchQueries)
        self.mustMatchConcepts = normalizedMustMatchConcepts
        self.shouldMatchConcepts = normalizedShouldMatchConcepts
        self.avoidConcepts = normalizedAvoidConcepts
        self.keywordProbes = normalizedKeywordProbes
        self.runtimeMin = Self.normalizedRuntime(runtimeMin)
        self.runtimeMax = Self.normalizedRuntime(runtimeMax)
        self.releaseYearMin = Self.normalizedYear(releaseYearMin)
        self.releaseYearMax = Self.normalizedYear(releaseYearMax)
        self.language = Self.normalizedLanguage(language)
        self.formatPreference = normalizedFormatPreference
        self.explanation = Self.normalizedExplanation(explanation)
    }

    /// Decodes Gemini's constrained JSON response and repairs underspecified intent with original prompt heuristics.
    static func decodeGeminiResponse(_ responseText: String, fallbackPrompt: String) throws -> MovieRecommendationIntent {
        guard let data = responseText.data(using: .utf8) else {
            throw MovieRecommendationError.malformedResponse
        }

        do {
            let payload = try JSONDecoder().decode(GeminiPayload.self, from: data)
            let intent = MovieRecommendationIntent(
                genres: payload.genres.compactMap(Self.genre(from:)),
                excludedGenres: payload.excludedGenres.compactMap(Self.genre(from:)),
                moods: payload.moods,
                themes: payload.themes,
                requiredThemes: payload.requiredThemes,
                preferredThemes: payload.preferredThemes,
                searchQueries: payload.searchQueries,
                mustMatchConcepts: payload.mustMatchConcepts,
                shouldMatchConcepts: payload.shouldMatchConcepts,
                avoidConcepts: payload.avoidConcepts,
                keywordProbes: payload.keywordProbes,
                runtimeMin: payload.runtimeMin,
                runtimeMax: payload.runtimeMax,
                releaseYearMin: payload.releaseYearMin,
                releaseYearMax: payload.releaseYearMax,
                language: payload.language,
                formatPreference: payload.formatPreference,
                explanation: payload.explanation,
                fallbackPrompt: fallbackPrompt
            )

            guard !intent.searchQueries.isEmpty else {
                throw MovieRecommendationError.invalidIntent
            }
            return intent
        } catch let error as MovieRecommendationError {
            throw error
        } catch {
            throw MovieRecommendationError.malformedResponse
        }
    }

    /// Maps model-provided genre text to the app's TMDB genre catalog.
    static func genre(from value: String) -> MoviesGenre? {
        let normalized = normalizeForMatching(value)

        if let genre = MoviesGenre.allCases.first(where: { normalizeForMatching($0.displayName) == normalized }) {
            return genre
        }

        switch normalized {
        case "sci fi", "scifi", "sciencefiction":
            return .scienceFiction
        case "tvmovie", "televisionmovie":
            return .tvMovie
        default:
            return MoviesGenre.fromStoredValue(value.lowercased())
        }
    }

    static func normalizedStrings(_ values: [String], limit: Int) -> [String] {
        Array(unique(values.compactMap(normalizedText)).prefix(limit))
    }

    private static func normalizedExplanation(_ value: String?) -> String? {
        guard let text = value.flatMap(normalizedText) else { return nil }
        return text
    }

    private static func normalizedText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func normalizedRuntime(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private static func normalizedYear(_ value: Int?) -> Int? {
        guard let value, (1878...2100).contains(value) else { return nil }
        return value
    }

    private static func normalizedLanguage(_ value: String?) -> String? {
        guard let text = value.flatMap(normalizedText)?.lowercased(), (2...5).contains(text.count) else { return nil }
        return text
    }

    private static func merged<T: Hashable>(_ lhs: [T], _ rhs: [T], limit: Int) -> [T] {
        Array(unique(lhs + rhs).prefix(limit))
    }

    private static func merged(_ lhs: [String], _ rhs: [String], limit: Int) -> [String] {
        normalizedStrings(lhs + rhs, limit: limit)
    }

    private static func unique<T: Hashable>(_ values: [T]) -> [T] {
        var seen = Set<T>()
        return values.filter { seen.insert($0).inserted }
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { value in
            seen.insert(normalizeForMatching(value)).inserted
        }
    }

    private static func normalizeForMatching(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

/// Raw JSON shape expected from Gemini before app-side normalization.
private struct GeminiPayload: Decodable {
    let genres: [String]
    let excludedGenres: [String]
    let moods: [String]
    let themes: [String]
    let requiredThemes: [String]
    let preferredThemes: [String]
    let searchQueries: [String]
    let mustMatchConcepts: [String]
    let shouldMatchConcepts: [String]
    let avoidConcepts: [String]
    let keywordProbes: [String]
    let runtimeMin: Int?
    let runtimeMax: Int?
    let releaseYearMin: Int?
    let releaseYearMax: Int?
    let language: String?
    let formatPreference: MovieFormatPreference
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case genres
        case excludedGenres
        case moods
        case themes
        case requiredThemes
        case preferredThemes
        case searchQueries
        case mustMatchConcepts
        case shouldMatchConcepts
        case avoidConcepts
        case keywordProbes
        case runtimeMin
        case runtimeMax
        case releaseYearMin
        case releaseYearMax
        case language
        case formatPreference
        case explanation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        genres = try container.decodeIfPresent([String].self, forKey: .genres) ?? []
        excludedGenres = try container.decodeIfPresent([String].self, forKey: .excludedGenres) ?? []
        moods = try container.decodeIfPresent([String].self, forKey: .moods) ?? []
        themes = try container.decodeIfPresent([String].self, forKey: .themes) ?? []
        requiredThemes = try container.decodeIfPresent([String].self, forKey: .requiredThemes) ?? []
        preferredThemes = try container.decodeIfPresent([String].self, forKey: .preferredThemes) ?? []
        searchQueries = try container.decodeIfPresent([String].self, forKey: .searchQueries) ?? []
        mustMatchConcepts = try container.decodeIfPresent([String].self, forKey: .mustMatchConcepts) ?? []
        shouldMatchConcepts = try container.decodeIfPresent([String].self, forKey: .shouldMatchConcepts) ?? []
        avoidConcepts = try container.decodeIfPresent([String].self, forKey: .avoidConcepts) ?? []
        keywordProbes = try container.decodeIfPresent([String].self, forKey: .keywordProbes) ?? []
        runtimeMin = try container.decodeIfPresent(Int.self, forKey: .runtimeMin)
        runtimeMax = try container.decodeIfPresent(Int.self, forKey: .runtimeMax)
        releaseYearMin = try container.decodeIfPresent(Int.self, forKey: .releaseYearMin)
        releaseYearMax = try container.decodeIfPresent(Int.self, forKey: .releaseYearMax)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        formatPreference = try container.decodeIfPresent(MovieFormatPreference.self, forKey: .formatPreference) ?? .any
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
    }
}

private struct PromptIntentRefinement {
    let genres: [MoviesGenre]
    let excludedGenres: [MoviesGenre]
    let moods: [String]
    let themes: [String]
    let requiredThemes: [String]
    let preferredThemes: [String]
    let avoidConcepts: [String]
    let keywordProbes: [String]
    let searchQueries: [String]
    let formatPreference: MovieFormatPreference

    init(prompt: String) {
        let text = prompt.normalizedForIntentRefinement
        let asksForAnimation = text.containsAny(["animated", "animation", "cartoon", "anime"])
        let asksForKids = text.containsAny(["kids", "children", "childrens", "toddlers"])
        let asksForChristmas = text.containsAny(["christmas", "xmas", "holiday", "holidays", "santa", "christmas eve"])
        let asksForFamily = text.containsAny(["family", "families", "parents"])

        var genres: [MoviesGenre] = []
        var excludedGenres: [MoviesGenre] = []
        var moods: [String] = []
        var themes: [String] = []
        var requiredThemes: [String] = []
        var preferredThemes: [String] = []
        var avoidConcepts: [String] = []
        var keywordProbes: [String] = []
        var searchQueries: [String] = []
        var formatPreference: MovieFormatPreference = .any

        if asksForChristmas {
            Self.append(.family, to: &genres)
            Self.append(.comedy, to: &genres)
            Self.append(.fantasy, to: &genres)
            Self.append("festive", to: &moods)
            Self.append("warm", to: &moods)
            Self.append("christmas", to: &themes)
            Self.append("holiday", to: &themes)
            Self.append("christmas", to: &requiredThemes)
            Self.append("holiday", to: &requiredThemes)
            Self.append("family", to: &preferredThemes, when: asksForFamily)
            keywordProbes.append(contentsOf: ["christmas", "christmas eve", "santa claus", "holiday"])
            searchQueries.append(contentsOf: [
                "christmas family comedy",
                "holiday family movie",
                "christmas family fantasy",
                "classic christmas family movie",
            ])
        }

        if asksForFamily {
            Self.append(.family, to: &genres)
            Self.append("family", to: &themes)
            Self.append("family", to: &preferredThemes)
        }

        if asksForAnimation || asksForKids {
            Self.append(.animation, to: &genres)
            formatPreference = .animatedPreferred
        } else if asksForFamily {
            Self.append(.animation, to: &excludedGenres)
            Self.append("animation", to: &avoidConcepts)
            Self.append("cartoon", to: &avoidConcepts)
            formatPreference = .liveActionPreferred
        }

        self.genres = genres
        self.excludedGenres = excludedGenres
        self.moods = moods
        self.themes = themes
        self.requiredThemes = requiredThemes
        self.preferredThemes = preferredThemes
        self.avoidConcepts = avoidConcepts
        self.keywordProbes = keywordProbes
        self.searchQueries = searchQueries
        self.formatPreference = formatPreference
    }

    private static func append<T: Equatable>(_ value: T, to values: inout [T], when condition: Bool = true) {
        guard condition, !values.contains(value) else { return }
        values.append(value)
    }
}

private extension String {
    var normalizedForIntentRefinement: String {
        lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func containsAny(_ values: [String]) -> Bool {
        values.contains { contains($0) }
    }
}
