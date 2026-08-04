import Foundation

extension MoviesGenre: Codable {}

/// Structured search intent produced from a user's natural-language movie prompt.
///
/// The app uses this value to query and rank real TMDB movies; it should not contain
/// model-selected movie titles or any user profile data.
struct MovieRecommendationIntent: Equatable, Sendable {
    static let maxGenres = 4
    static let maxMoods = 5
    static let maxThemes = 8
    static let maxSearchQueries = 4

    let genres: [MoviesGenre]
    let moods: [String]
    let themes: [String]
    let searchQueries: [String]
    let explanation: String?

    init(
        genres: [MoviesGenre] = [],
        moods: [String] = [],
        themes: [String] = [],
        searchQueries: [String] = [],
        explanation: String? = nil,
        fallbackPrompt: String? = nil
    ) {
        self.genres = Array(Self.unique(genres).prefix(Self.maxGenres))
        self.moods = Self.normalizedStrings(moods, limit: Self.maxMoods)
        self.themes = Self.normalizedStrings(themes, limit: Self.maxThemes)

        var queries = searchQueries
        if queries.isEmpty, let fallbackPrompt {
            queries.append(fallbackPrompt)
        }
        self.searchQueries = Self.normalizedStrings(queries, limit: Self.maxSearchQueries)
        self.explanation = Self.normalizedExplanation(explanation)
    }

    /// Decodes Gemini's constrained JSON response and repairs missing search queries with the original prompt.
    static func decodeGeminiResponse(_ responseText: String, fallbackPrompt: String) throws -> MovieRecommendationIntent {
        guard let data = responseText.data(using: .utf8) else {
            throw MovieRecommendationError.malformedResponse
        }

        do {
            let payload = try JSONDecoder().decode(GeminiPayload.self, from: data)
            let intent = MovieRecommendationIntent(
                genres: payload.genres.compactMap(Self.genre(from:)),
                moods: payload.moods,
                themes: payload.themes,
                searchQueries: payload.searchQueries,
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
    let moods: [String]
    let themes: [String]
    let searchQueries: [String]
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case genres
        case moods
        case themes
        case searchQueries
        case explanation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        genres = try container.decodeIfPresent([String].self, forKey: .genres) ?? []
        moods = try container.decodeIfPresent([String].self, forKey: .moods) ?? []
        themes = try container.decodeIfPresent([String].self, forKey: .themes) ?? []
        searchQueries = try container.decodeIfPresent([String].self, forKey: .searchQueries) ?? []
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
    }
}
