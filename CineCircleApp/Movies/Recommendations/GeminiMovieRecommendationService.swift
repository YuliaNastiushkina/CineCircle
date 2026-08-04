import FirebaseAI
import Foundation

/// Converts movie prompts into structured TMDB search intent using Gemini through Firebase AI.
struct GeminiMovieRecommendationService: MovieRecommendationServiceProtocol {
    private let modelName: String

    init(modelName: String = "gemini-3.5-flash-lite") {
        self.modelName = modelName
    }

    func recommendationIntent(for prompt: String) async throws -> MovieRecommendationIntent {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw MovieRecommendationError.emptyPrompt
        }

        let model = FirebaseAI.firebaseAI(backend: .googleAI()).generativeModel(
            modelName: modelName,
            generationConfig: GenerationConfig(
                temperature: 0.15,
                candidateCount: 1,
                maxOutputTokens: 900,
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

    /// Compact instruction sent with each request to keep Gemini focused on search planning, not final movie selection.
    static let systemInstruction = """
    You convert a user's movie request into a structured TMDB search plan.
    Return only JSON matching the schema.
    Do not recommend specific movie titles and do not invent movies.
    Use English values even if the user prompt is not in English.

    Split intent into:
    - mustMatchConcepts: core story, setting, tone, or constraints the final movies should strongly match.
    - shouldMatchConcepts: helpful secondary preferences.
    - avoidConcepts: themes, tones, or formats the user does not want.
    - keywordProbes: concrete TMDB keyword search probes, not full sentences.
    - searchQueries: concise TMDB text probes used to gather candidates, not final recommendations.

    Genres are soft hints for TMDB discover. Prefer broad OR-friendly genre hints over narrow combinations.
    requiredThemes mirrors the most important mustMatchConcepts for backward compatibility.
    preferredThemes mirrors the most important shouldMatchConcepts for backward compatibility.
    Keep searchQueries concrete: nouns, settings, actions, genres, and moods.
    Avoid vague emotional queries by themselves; combine mood with genre or story context.
    Do not add Animation unless the user asks for animated, animation, cartoon, anime, or kids movies.
    For family prompts, prefer live-action family movies unless animation is explicit.
    Runtime, year, and language are strict only when the user explicitly asks for them.

    Examples:
    User: Christmas movies for family
    Intent: genres Family, Comedy, Fantasy; excludedGenres Animation; mustMatchConcepts christmas, holiday; shouldMatchConcepts family, warm, festive; avoidConcepts animation, cartoon; keywordProbes christmas, christmas eve, santa claus, holiday; requiredThemes christmas, holiday; preferredThemes family, warm, festive; formatPreference liveActionPreferred; searchQueries christmas family comedy, holiday family movie, classic christmas family movie.

    User: animated christmas movies for kids
    Intent: genres Animation, Family; mustMatchConcepts christmas, holiday; shouldMatchConcepts kids, festive; keywordProbes christmas, holiday, animation; requiredThemes christmas, holiday; preferredThemes kids, festive; formatPreference animatedPreferred; searchQueries animated christmas family, christmas movies for kids.

    User: adventure movie about hidden treasure and a map
    Intent: genres Adventure, Action, Mystery; mustMatchConcepts treasure hunt, hidden treasure, map; shouldMatchConcepts artifact hunt, clues, adventure; keywordProbes treasure hunt, hidden treasure, treasure map, artifact; requiredThemes treasure hunt, hidden treasure; preferredThemes map, artifact hunt; formatPreference any; searchQueries treasure hunt adventure, hidden treasure movie, treasure map adventure, artifact adventure.
    """

    /// Firebase AI response schema used to request constrained JSON instead of free-form text.
    static let intentSchema = Schema.object(
        properties: [
            "genres": .array(
                items: genreSchema,
                description: "Up to four broad matching TMDB movie genres.",
                maxItems: MovieRecommendationIntent.maxGenres
            ),
            "excludedGenres": .array(
                items: genreSchema,
                description: "Genres to softly downrank, not hard-filter.",
                maxItems: MovieRecommendationIntent.maxExcludedGenres
            ),
            "moods": .array(
                items: .string(description: "Short mood or tone tag."),
                description: "Short mood words, such as funny, comforting, uplifting, dark, romantic.",
                maxItems: MovieRecommendationIntent.maxMoods
            ),
            "themes": .array(
                items: .string(description: "Short theme or story concept."),
                description: "Concrete story themes, settings, or concepts from the prompt.",
                maxItems: MovieRecommendationIntent.maxThemes
            ),
            "requiredThemes": .array(
                items: .string(description: "Backward-compatible strong prompt concept."),
                description: "Important concepts mirrored from mustMatchConcepts.",
                maxItems: MovieRecommendationIntent.maxRequiredThemes
            ),
            "preferredThemes": .array(
                items: .string(description: "Backward-compatible soft prompt concept."),
                description: "Helpful concepts mirrored from shouldMatchConcepts.",
                maxItems: MovieRecommendationIntent.maxPreferredThemes
            ),
            "mustMatchConcepts": .array(
                items: .string(description: "Core concept the final movie should strongly match."),
                description: "Core concepts from the prompt, such as christmas, treasure hunt, sad ending excluded by avoidConcepts.",
                maxItems: MovieRecommendationIntent.maxConcepts
            ),
            "shouldMatchConcepts": .array(
                items: .string(description: "Helpful secondary concept."),
                description: "Softer preferences that improve ranking but should not over-filter retrieval.",
                maxItems: MovieRecommendationIntent.maxConcepts
            ),
            "avoidConcepts": .array(
                items: .string(description: "Concept, tone, or format to downrank."),
                description: "Concepts the user does not want, such as sad ending, tragedy, animation.",
                maxItems: MovieRecommendationIntent.maxConcepts
            ),
            "keywordProbes": .array(
                items: .string(description: "Concise keyword probe for TMDB search/keyword."),
                description: "Concrete TMDB keyword lookup probes, such as christmas, treasure map, haunted house.",
                maxItems: MovieRecommendationIntent.maxKeywordProbes
            ),
            "searchQueries": .array(
                items: .string(description: "Concise English TMDB movie search phrase."),
                description: "Three to six concise search/movie probes used only to collect candidates.",
                minItems: 1,
                maxItems: MovieRecommendationIntent.maxSearchQueries
            ),
            "runtimeMin": .integer(description: "Minimum runtime in minutes when explicitly requested.", nullable: true),
            "runtimeMax": .integer(description: "Maximum runtime in minutes when explicitly requested.", nullable: true),
            "releaseYearMin": .integer(description: "Minimum release year when explicitly requested.", nullable: true),
            "releaseYearMax": .integer(description: "Maximum release year when explicitly requested.", nullable: true),
            "language": .string(description: "ISO 639-1 original language code when explicitly requested.", nullable: true),
            "formatPreference": .enumeration(
                values: MovieFormatPreference.allSchemaValues,
                description: "Whether live-action or animation should be softly preferred."
            ),
            "explanation": .string(
                description: "One short sentence explaining the overall recommendation direction.",
                nullable: true
            ),
        ],
        optionalProperties: [
            "excludedGenres",
            "avoidConcepts",
            "runtimeMin",
            "runtimeMax",
            "releaseYearMin",
            "releaseYearMax",
            "language",
            "explanation",
        ],
        propertyOrdering: [
            "genres",
            "excludedGenres",
            "moods",
            "themes",
            "requiredThemes",
            "preferredThemes",
            "mustMatchConcepts",
            "shouldMatchConcepts",
            "avoidConcepts",
            "keywordProbes",
            "searchQueries",
            "runtimeMin",
            "runtimeMax",
            "releaseYearMin",
            "releaseYearMax",
            "language",
            "formatPreference",
            "explanation",
        ]
    )

    private static let genreSchema = Schema.enumeration(
        values: MoviesGenre.allCases.map(\.displayName),
        description: "TMDB movie genre."
    )
}

private extension MovieFormatPreference {
    static let allSchemaValues = [
        MovieFormatPreference.any.rawValue,
        MovieFormatPreference.liveActionPreferred.rawValue,
        MovieFormatPreference.animatedPreferred.rawValue,
    ]
}
