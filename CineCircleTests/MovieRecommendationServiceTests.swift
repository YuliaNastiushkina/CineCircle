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
        XCTAssertEqual(intent.moods, ["funny", "comforting", "dark", "romantic", "playful"])
        XCTAssertEqual(intent.themes, ["pirates", "treasure", "sea", "quest", "map", "island", "gold", "ship"])
        XCTAssertEqual(intent.searchQueries, ["pirate comedy", "treasure hunt", "sea adventure", "funny pirates"])
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
        XCTAssertEqual(intent.searchQueries, ["I want a comedy with pirates who hunt for treasure"])
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
        XCTAssertEqual(requests[2].query["with_genres"], "35,12")
        XCTAssertEqual(requests[2].query["sort_by"], "popularity.desc")
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

    private func makeMovie(
        id: Int,
        title: String,
        overview: String,
        posterPath: String? = nil,
        voteAverage: Double,
        voteCount: Int,
        genreIDs: [Int]
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
            genreIDs: genreIDs
        )
    }
}
