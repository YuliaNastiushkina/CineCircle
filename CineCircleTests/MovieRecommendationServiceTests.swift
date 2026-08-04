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
}
