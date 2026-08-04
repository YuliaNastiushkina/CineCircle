// swiftlint:disable type_body_length
@testable import CineCircle
import XCTest

final class MovieRecommendationServiceTests: XCTestCase {
    func testIntentNormalizationRemovesEmptyValuesDeduplicatesAndCapsArrays() {
        let intent = MovieRecommendationIntent(
            genres: [.comedy, .comedy, .adventure, .romance, .horror, .mystery],
            moods: [" funny ", "Funny", "", "comforting", "dark", "romantic", "playful"],
            themes: [" pirates ", "Pirates", "treasure", "sea", "quest", "map", "island", "gold", "ship"],
            searchQueries: [" pirate comedy ", "Pirate Comedy", "treasure hunt", "", "sea adventure", "funny pirates"],
            explanation: "  Light adventure matches.  "
        )

        XCTAssertEqual(intent.genres, [.comedy, .adventure, .romance, .horror])
        XCTAssertEqual(intent.excludedGenres, [])
        XCTAssertEqual(intent.moods, ["funny", "comforting", "dark", "romantic", "playful"])
        XCTAssertEqual(intent.themes, ["pirates", "treasure", "sea", "quest", "map", "island", "gold", "ship"])
        XCTAssertEqual(intent.requiredThemes, [])
        XCTAssertEqual(intent.preferredThemes, [])
        XCTAssertEqual(intent.mustMatchConcepts, [])
        XCTAssertEqual(intent.shouldMatchConcepts, ["pirates", "treasure", "sea", "quest", "map", "island", "gold", "ship"])
        XCTAssertEqual(intent.avoidConcepts, [])
        XCTAssertEqual(intent.keywordProbes, ["pirates", "treasure", "sea", "quest", "map", "island", "gold", "ship"])
        XCTAssertEqual(intent.searchQueries, ["pirate comedy", "treasure hunt", "sea adventure", "funny pirates"])
        XCTAssertEqual(intent.searchQueries.count, 4)
        XCTAssertEqual(intent.formatPreference, .any)
        XCTAssertEqual(intent.explanation, "Light adventure matches.")
    }

    func testDecodeGeminiResponseMapsDisplayGenreNames() throws {
        let json = """
        {
          "genres": ["Comedy", "Adventure", "Science Fiction"],
          "moods": ["funny", "playful"],
          "themes": ["pirates", "treasure hunt"],
          "searchQueries": ["pirate treasure comedy", "funny treasure hunt adventure"],
          "explanation": "Light adventure comedies should match this prompt."
        }
        """

        let intent = try MovieRecommendationIntent.decodeGeminiResponse(
            json,
            fallbackPrompt: "I want pirates"
        )

        XCTAssertEqual(intent.genres, [.comedy, .adventure, .scienceFiction])
        XCTAssertEqual(intent.searchQueries, ["pirate treasure comedy", "funny treasure hunt adventure"])
        XCTAssertEqual(intent.themes, ["pirates", "treasure hunt"])
        XCTAssertEqual(intent.mustMatchConcepts, [])
        XCTAssertEqual(intent.shouldMatchConcepts, ["pirates", "treasure hunt", "funny", "playful"])
        XCTAssertEqual(intent.keywordProbes, ["pirates", "treasure hunt"])
    }

    func testDecodeGeminiResponseRepairsMissingSearchQueriesWithFallbackPrompt() throws {
        let json = """
        {
          "genres": ["Romance", "Comedy"],
          "moods": ["comforting"],
          "themes": ["breakup recovery"],
          "searchQueries": [],
          "explanation": null
        }
        """

        let intent = try MovieRecommendationIntent.decodeGeminiResponse(
            json,
            fallbackPrompt: "something after breakup"
        )

        XCTAssertEqual(intent.genres, [.romance, .comedy])
        XCTAssertEqual(intent.searchQueries, ["something after breakup"])
    }

    func testDecodeGeminiResponseThrowsForMalformedJSON() {
        XCTAssertThrowsError(
            try MovieRecommendationIntent.decodeGeminiResponse("not json", fallbackPrompt: "pirates")
        ) { error in
            XCTAssertEqual(error as? MovieRecommendationError, .malformedResponse)
        }
    }

    func testIntentRefinementAddsHolidayFamilySoftConstraints() async throws {
        let service = FallbackMovieRecommendationService()
        let intent = try await service.recommendationIntent(for: "Christmas movies for family")

        XCTAssertTrue(intent.genres.contains(.family))
        XCTAssertTrue(intent.genres.contains(.comedy))
        XCTAssertTrue(intent.genres.contains(.fantasy))
        XCTAssertTrue(intent.excludedGenres.contains(.animation))
        XCTAssertTrue(intent.requiredThemes.contains("christmas"))
        XCTAssertTrue(intent.requiredThemes.contains("holiday"))
        XCTAssertTrue(intent.preferredThemes.contains("family"))
        XCTAssertTrue(intent.mustMatchConcepts.contains("christmas"))
        XCTAssertTrue(intent.mustMatchConcepts.contains("holiday"))
        XCTAssertTrue(intent.shouldMatchConcepts.contains("family"))
        XCTAssertTrue(intent.avoidConcepts.contains("animation"))
        XCTAssertTrue(intent.keywordProbes.contains("santa claus"))
        XCTAssertEqual(intent.formatPreference, .liveActionPreferred)
        XCTAssertEqual(intent.searchQueries.prefix(4), [
            "christmas family comedy",
            "holiday family movie",
            "christmas family fantasy",
            "classic christmas family movie",
        ])
    }

    func testIntentRefinementKeepsAnimationWhenExplicitlyRequested() async throws {
        let service = FallbackMovieRecommendationService()
        let intent = try await service.recommendationIntent(for: "animated christmas movies for kids")

        XCTAssertTrue(intent.genres.contains(.animation))
        XCTAssertFalse(intent.excludedGenres.contains(.animation))
        XCTAssertFalse(intent.avoidConcepts.contains("animation"))
        XCTAssertEqual(intent.formatPreference, .animatedPreferred)
    }

    func testPlannerBuildsGeneralTreasureConceptsWithoutSpecificTitleSeed() async throws {
        let service = FallbackMovieRecommendationService()
        let intent = try await service.recommendationIntent(for: "Adventure movie about hidden treasure and a map")

        XCTAssertTrue(intent.genres.contains(.adventure))
        XCTAssertTrue(intent.themes.contains("treasure hunt"))
        XCTAssertTrue(intent.mustMatchConcepts.contains("treasure hunt"))
        XCTAssertTrue(intent.keywordProbes.contains("hidden treasure"))
        XCTAssertTrue(intent.keywordProbes.contains("treasure map"))
        XCTAssertTrue(intent.searchQueries.contains("treasure hunt adventure"))
        XCTAssertFalse(intent.searchQueries.contains("national treasure"))
    }

    func testFallbackServiceThrowsForEmptyPrompt() async {
        let service = FallbackMovieRecommendationService()

        do {
            _ = try await service.recommendationIntent(for: "   ")
            XCTFail("Empty prompt should throw")
        } catch {
            XCTAssertEqual(error as? MovieRecommendationError, .emptyPrompt)
        }
    }

    func testFallbackServiceMapsPirateComedyPrompt() async throws {
        let service = FallbackMovieRecommendationService()
        let intent = try await service.recommendationIntent(
            for: "I want a comedy with pirates who hunt for treasure"
        )

        XCTAssertTrue(intent.genres.contains(.comedy))
        XCTAssertTrue(intent.genres.contains(.adventure))
        XCTAssertTrue(intent.themes.contains("pirates"))
        XCTAssertTrue(intent.themes.contains("treasure hunt"))
        XCTAssertEqual(intent.searchQueries, [
            "pirate treasure comedy",
            "pirate treasure adventure",
            "treasure hunt adventure",
            "pirates comedy adventure",
            "I want a comedy with pirates who hunt for treasure",
        ])
    }

    func testFallbackServiceMapsBreakupComfortPrompt() async throws {
        let service = FallbackMovieRecommendationService()
        let intent = try await service.recommendationIntent(
            for: "I want something that can help me feel better after breakup"
        )

        XCTAssertTrue(intent.genres.contains(.comedy))
        XCTAssertTrue(intent.genres.contains(.romance))
        XCTAssertTrue(intent.moods.contains("comforting"))
        XCTAssertTrue(intent.themes.contains("breakup recovery"))
    }

    func testFallbackServiceKeepsUnknownPromptAsSearchQuery() async throws {
        let service = FallbackMovieRecommendationService()
        let intent = try await service.recommendationIntent(for: "quiet winter story")

        XCTAssertTrue(intent.genres.isEmpty)
        XCTAssertEqual(intent.searchQueries, ["quiet winter story"])
    }

    func testTMDBRecommendationServiceUsesSearchAndDiscoverQueries() async throws {
        var requests: [(path: String, query: [String: String])] = []
        let client = MockAPIClient { path, query in
            requests.append((path, query))
            return MovieResponse(results: [], page: 1, totalResults: 0, totalPages: 1)
        }
        let service = TMDBMovieRecommendationMovieService(client: client)
        let intent = MovieRecommendationIntent(
            genres: [.comedy, .adventure],
            searchQueries: ["pirate comedy", "treasure hunt"]
        )

        _ = try await service.rankedMovies(for: intent)

        XCTAssertEqual(requests.map(\.path), ["search/movie", "search/movie", "discover/movie"])
        XCTAssertEqual(requests[0].query["query"], "pirate comedy")
        XCTAssertEqual(requests[1].query["query"], "treasure hunt")
        XCTAssertEqual(requests[2].query["with_genres"], "35|12")
        XCTAssertEqual(requests[2].query["sort_by"], "popularity.desc")
    }

    func testTMDBRecommendationServiceUsesSemanticKeywordDiscoveries() async throws {
        var requests: [(path: String, query: [String: String])] = []
        let client = MockAPIClient { path, query in
            requests.append((path, query))

            if path == "search/keyword" {
                return MovieKeywordResponse(results: [MovieKeyword(id: 207_317, name: query["query"] ?? "")])
            }

            return MovieResponse(results: [], page: 1, totalResults: 0, totalPages: 1)
        }
        let service = TMDBMovieRecommendationMovieService(client: client)
        let intent = MovieRecommendationIntent(
            genres: [.family, .comedy, .fantasy],
            themes: ["christmas", "family"],
            requiredThemes: ["christmas"],
            searchQueries: ["christmas family comedy"]
        )

        _ = try await service.rankedMovies(for: intent)

        XCTAssertTrue(requests.contains { $0.path == "search/keyword" && $0.query["query"] == "christmas" })
        XCTAssertTrue(requests.contains { $0.path == "search/keyword" && $0.query["query"] == "santa claus" })
        XCTAssertTrue(requests.contains { $0.path == "discover/movie" && $0.query["with_keywords"] == "207317" })
        XCTAssertTrue(requests.contains { $0.path == "discover/movie" && $0.query["with_genres"] == "10751|35" })
    }

    func testTMDBRecommendationServiceAppliesPlannerDiscoverFilters() async throws {
        var discoverQuery: [String: String] = [:]
        let client = MockAPIClient { path, query in
            if path == "discover/movie" {
                discoverQuery = query
            }

            return MovieResponse(results: [], page: 1, totalResults: 0, totalPages: 1)
        }
        let service = TMDBMovieRecommendationMovieService(client: client)
        let intent = MovieRecommendationIntent(
            genres: [.comedy, .romance],
            searchQueries: [],
            runtimeMax: 110,
            releaseYearMin: 2010,
            releaseYearMax: 2024,
            language: "fr"
        )

        _ = try await service.rankedMovies(for: intent)

        XCTAssertEqual(discoverQuery["with_genres"], "35|10749")
        XCTAssertEqual(discoverQuery["with_runtime.lte"], "110")
        XCTAssertEqual(discoverQuery["primary_release_date.gte"], "2010-01-01")
        XCTAssertEqual(discoverQuery["primary_release_date.lte"], "2024-12-31")
        XCTAssertEqual(discoverQuery["with_original_language"], "fr")
    }

    func testTMDBRecommendationServiceDeduplicatesAndRanksBestMatchFirst() async throws {
        let genericComedy = makeMovie(
            id: 1,
            title: "Generic Comedy",
            overview: "Friends have a funny weekend.",
            voteAverage: 7.2,
            voteCount: 500,
            genreIDs: [MoviesGenre.comedy.id]
        )
        let pirateAdventure = makeMovie(
            id: 2,
            title: "Pirate Treasure Comedy",
            overview: "A funny pirate crew hunts for treasure across the sea.",
            posterPath: "/poster.jpg",
            voteAverage: 7.8,
            voteCount: 900,
            genreIDs: [MoviesGenre.comedy.id, MoviesGenre.adventure.id]
        )
        let lowSignalMovie = makeMovie(
            id: 3,
            title: "Quiet Drama",
            overview: "A slow drama.",
            voteAverage: 9.0,
            voteCount: 5,
            genreIDs: [MoviesGenre.drama.id]
        )

        let client = MockAPIClient { path, query in
            if path == "search/keyword" {
                return MovieKeywordResponse(results: [])
            }

            if path == "search/movie", query["query"] == "pirate comedy" {
                return MovieResponse(results: [genericComedy, pirateAdventure], page: 1, totalResults: 2, totalPages: 1)
            }

            if path == "search/movie", query["query"] == "treasure hunt" {
                return MovieResponse(results: [pirateAdventure, lowSignalMovie], page: 1, totalResults: 2, totalPages: 1)
            }

            return MovieResponse(results: [genericComedy], page: 1, totalResults: 1, totalPages: 1)
        }
        let service = TMDBMovieRecommendationMovieService(client: client)
        let intent = MovieRecommendationIntent(
            genres: [.comedy, .adventure],
            themes: ["pirates", "treasure hunt"],
            searchQueries: ["pirate comedy", "treasure hunt"]
        )

        let movies = try await service.rankedMovies(for: intent)

        XCTAssertEqual(movies.map(\.id), [2, 1, 3])
    }

    func testTMDBRecommendationServiceRespectsCandidateLimit() async throws {
        let movies = (1...5).map { id in
            makeMovie(id: id, title: "Movie \(id)", overview: "Comedy", voteAverage: 7, voteCount: 100, genreIDs: [MoviesGenre.comedy.id])
        }
        let client = MockAPIClient { _, _ in
            MovieResponse(results: movies, page: 1, totalResults: movies.count, totalPages: 1)
        }
        let service = TMDBMovieRecommendationMovieService(client: client, candidateLimit: 3)
        let intent = MovieRecommendationIntent(genres: [.comedy], searchQueries: ["comedy"])

        let rankedMovies = try await service.rankedMovies(for: intent)

        XCTAssertEqual(rankedMovies.count, 3)
    }

    func testTMDBRecommendationServiceUsesPopularityForCloseRelevanceMatches() async throws {
        let lesserKnownComedy = makeMovie(
            id: 1,
            title: "Small Comedy",
            overview: "A funny comedy about friends.",
            voteAverage: 7.0,
            voteCount: 25,
            genreIDs: [MoviesGenre.comedy.id],
            popularity: 8
        )
        let popularComedy = makeMovie(
            id: 2,
            title: "Popular Comedy",
            overview: "A funny comedy about friends.",
            voteAverage: 7.8,
            voteCount: 9000,
            genreIDs: [MoviesGenre.comedy.id],
            popularity: 140
        )
        let client = MockAPIClient { _, _ in
            MovieResponse(results: [lesserKnownComedy, popularComedy], page: 1, totalResults: 2, totalPages: 1)
        }
        let service = TMDBMovieRecommendationMovieService(client: client)
        let intent = MovieRecommendationIntent(genres: [.comedy], searchQueries: ["funny comedy"])

        let rankedMovies = try await service.rankedMovies(for: intent)

        XCTAssertEqual(rankedMovies.map(\.id), [2, 1])
    }

    func testTMDBRecommendationServiceKeepsStrongRelevanceAbovePopularity() async throws {
        let popularGenericAdventure = makeMovie(
            id: 1,
            title: "Popular Adventure",
            overview: "A famous expedition crosses the wilderness.",
            voteAverage: 8.2,
            voteCount: 12000,
            genreIDs: [MoviesGenre.adventure.id]
        )
        let specificTreasureAdventure = makeMovie(
            id: 2,
            title: "Hidden Treasure Map",
            overview: "An adventurer follows clues to a lost relic and hidden treasure.",
            voteAverage: 6.8,
            voteCount: 120,
            genreIDs: [MoviesGenre.adventure.id]
        )
        let client = MockAPIClient { path, _ in
            if path == "search/keyword" {
                return MovieKeywordResponse(results: [])
            }

            return MovieResponse(results: [popularGenericAdventure, specificTreasureAdventure], page: 1, totalResults: 2, totalPages: 1)
        }
        let service = TMDBMovieRecommendationMovieService(client: client)
        let intent = MovieRecommendationIntent(
            genres: [.adventure],
            searchQueries: [],
            mustMatchConcepts: ["treasure hunt"]
        )

        let rankedMovies = try await service.rankedMovies(for: intent)

        XCTAssertEqual(rankedMovies.map(\.id), [2, 1])
    }

    func testScorerRewardsMultipleThemeMatchesOverGenericPopularity() {
        let scorer = MovieRecommendationScorer()
        let intent = MovieRecommendationIntent(
            genres: [.comedy, .adventure],
            moods: ["funny"],
            themes: ["pirates", "treasure hunt"],
            searchQueries: ["pirate treasure comedy"]
        )
        let genericPopularAdventure = makeMovie(
            id: 1,
            title: "Popular Adventure",
            overview: "A large scale quest across the sea.",
            posterPath: "/popular.jpg",
            voteAverage: 8.2,
            voteCount: 8000,
            genreIDs: [MoviesGenre.adventure.id]
        )
        let specificPirateComedy = makeMovie(
            id: 2,
            title: "Pirate Treasure Comedy",
            overview: "A funny pirate crew hunts for hidden treasure.",
            posterPath: "/pirates.jpg",
            voteAverage: 6.8,
            voteCount: 120,
            genreIDs: [MoviesGenre.comedy.id, MoviesGenre.adventure.id]
        )

        XCTAssertGreaterThan(
            scorer.score(specificPirateComedy, intent: intent, appearanceCount: 1),
            scorer.score(genericPopularAdventure, intent: intent, appearanceCount: 1)
        )
    }

    func testScorerSoftlyPrefersHolidayFamilyLiveActionOverGenericAnimation() async throws {
        let scorer = MovieRecommendationScorer()
        let service = FallbackMovieRecommendationService()
        let intent = try await service.recommendationIntent(for: "Christmas movies for family")
        let liveActionHolidayMovie = makeMovie(
            id: 1,
            title: "A Winter Visit",
            overview: "A warm family comedy set during Christmas as relatives reconnect for the holidays.",
            posterPath: "/holiday.jpg",
            voteAverage: 6.9,
            voteCount: 180,
            genreIDs: [MoviesGenre.family.id, MoviesGenre.comedy.id]
        )
        let genericAnimatedMovie = makeMovie(
            id: 2,
            title: "Animal Adventure",
            overview: "Animated friends leave home for a colorful family journey.",
            posterPath: "/animated.jpg",
            voteAverage: 8.2,
            voteCount: 2500,
            genreIDs: [MoviesGenre.animation.id, MoviesGenre.family.id, MoviesGenre.adventure.id]
        )

        XCTAssertGreaterThan(
            scorer.score(liveActionHolidayMovie, intent: intent, appearanceCount: 1),
            scorer.score(genericAnimatedMovie, intent: intent, appearanceCount: 1)
        )
    }

    func testScorerExpandsComfortMoodTerms() {
        let scorer = MovieRecommendationScorer()
        let intent = MovieRecommendationIntent(
            genres: [.comedy, .romance],
            moods: ["comforting"],
            themes: ["breakup recovery"],
            searchQueries: ["uplifting romantic comedy"]
        )
        let hopefulComedy = makeMovie(
            id: 1,
            title: "Moving On",
            overview: "A heartwarming and hopeful romantic comedy about healing after heartbreak.",
            posterPath: "/hope.jpg",
            voteAverage: 7.0,
            voteCount: 250,
            genreIDs: [MoviesGenre.comedy.id, MoviesGenre.romance.id]
        )
        let bleakDrama = makeMovie(
            id: 2,
            title: "After Heartbreak",
            overview: "A bleak and devastating drama about a painful breakup.",
            posterPath: "/bleak.jpg",
            voteAverage: 8.5,
            voteCount: 3000,
            genreIDs: [MoviesGenre.drama.id, MoviesGenre.romance.id]
        )

        XCTAssertGreaterThan(
            scorer.score(hopefulComedy, intent: intent, appearanceCount: 1),
            scorer.score(bleakDrama, intent: intent, appearanceCount: 1)
        )
    }

    private func makeMovie(
        id: Int,
        title: String,
        overview: String,
        posterPath: String? = nil,
        voteAverage: Double,
        voteCount: Int,
        genreIDs: [Int],
        popularity: Double? = nil
    ) -> RemoteMovie {
        RemoteMovie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            releaseDate: "2024-01-01",
            originalLanguage: "en",
            genreIDs: genreIDs,
            popularity: popularity
        )
    }
}
