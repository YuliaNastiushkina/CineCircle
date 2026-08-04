import FirebaseAI
import Foundation

/// Converts movie prompts into structured TMDB search intent using Gemini through Firebase AI.
struct GeminiMovieRecommendationService: MovieRecommendationServiceProtocol {
    private let modelName: String

    init(modelName: String = "gemini-2.5-flash-lite") {
        self.modelName = modelName
    }

    func recommendationIntent(for prompt: String) async throws -> MovieRecommendationIntent {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw MovieRecommendationError.emptyPrompt
        }

        let model = FirebaseAI.firebaseAI().generativeModel(
            modelName: modelName,
            generationConfig: GenerationConfig(
                temperature: 0.2,
                candidateCount: 1,
                maxOutputTokens: 512,
                responseMIMEType: "application/json",
                responseSchema: Self.intentSchema
            ),
            systemInstruction: ModelContent(role: nil, parts: Self.systemInstruction)
        )

        let response = try await model.generateContent(trimmedPrompt)
        guard let text = response.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw MovieRecommendationError.missingResponseText
        }

        return try MovieRecommendationIntent.decodeGeminiResponse(text, fallbackPrompt: trimmedPrompt)
    }

    /// Compact instruction sent with each request to keep Gemini focused on search intent extraction.
    static let systemInstruction = """
    You convert a user's movie request into structured search intent for TMDB.
    Return only JSON matching the schema.
    Do not recommend specific movie titles.
    Prefer concise genres, moods, themes, and search queries.
    Use English search terms even if the user prompt is not in English.
    """

    /// Firebase AI response schema used to request constrained JSON instead of free-form text.
    static let intentSchema = Schema.object(
        properties: [
            "genres": .array(
                items: .enumeration(
                    values: MoviesGenre.allCases.map(\.displayName),
                    description: "TMDB movie genres."
                ),
                description: "Up to four matching movie genres.",
                maxItems: MovieRecommendationIntent.maxGenres
            ),
            "moods": .array(
                items: .string(description: "Short mood or tone tag."),
                description: "Short mood words, such as funny, comforting, dark, romantic.",
                maxItems: MovieRecommendationIntent.maxMoods
            ),
            "themes": .array(
                items: .string(description: "Short theme or story concept."),
                description: "Concrete story themes, settings, or concepts from the prompt.",
                maxItems: MovieRecommendationIntent.maxThemes
            ),
            "searchQueries": .array(
                items: .string(description: "Concise English TMDB movie search phrase."),
                description: "Two to four concise search phrases for TMDB search/movie.",
                minItems: 1,
                maxItems: MovieRecommendationIntent.maxSearchQueries
            ),
            "explanation": .string(
                description: "One short sentence explaining the overall recommendation direction.",
                nullable: true
            ),
        ],
        optionalProperties: ["explanation"],
        propertyOrdering: ["genres", "moods", "themes", "searchQueries", "explanation"]
    )
}
