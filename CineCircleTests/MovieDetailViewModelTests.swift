@testable import CineCircle
import XCTest

@MainActor
final class MovieDetailViewModelTests: XCTestCase {
    func testFetchMovieDetailsSuccess() async {
        // Given
        let mockClient = MockAPIClient { path, _ in
            XCTAssertEqual(path, "movie/1")
            return RemoteMovieDetail(
                id: 1,
                title: "Test Movie",
                overview: "Overview",
                posterPath: "/poster.jpg",
                backdropPath: "/backdrop.jpg",
                voteAverage: 8.5,
                releaseDate: "2025-01-01",
                runtime: 120,
                originalLanguage: "EN",
                genres: [],
                productionCompanies: []
            )
        }

        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchMovieDetails(for: 1)

        // Then
        XCTAssertEqual(sut.movieDetail?.title, "Test Movie")
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchMovieDetailsFailure() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            throw URLError(.timedOut)
        }

        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchMovieDetails(for: 1)

        // Then
        XCTAssertNil(sut.movieDetail)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testFetchCastAndCrewSuccess() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            MovieCreditsResponse(
                cast: [MovieCast(id: 1, name: "John Doe")],
                crew: [MovieCrew(id: 1, name: "Margaret Wild", job: "Director")]
            )
        }

        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchCastAndCrew(for: 1)

        // Then
        XCTAssertEqual(sut.cast.first?.name, "John Doe")
        XCTAssertEqual(sut.director, "Margaret Wild")
    }

    func testFetchCastAndCrewFailure() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            throw URLError(.timedOut)
        }
        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchCastAndCrew(for: 1)

        // Then
        XCTAssertTrue(sut.cast.isEmpty)
        XCTAssertNil(sut.director)
        XCTAssertNil(sut.producer)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testFetchCastAndCrewMultipleDirectorsProducers() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            MovieCreditsResponse(
                cast: [MovieCast(id: 1, name: "John Doe")],
                crew: [
                    MovieCrew(id: 1, name: "Director One", job: "Director"),
                    MovieCrew(id: 2, name: "Producer One", job: "Producer"),
                ]
            )
        }
        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchCastAndCrew(for: 1)

        // Then
        XCTAssertEqual(sut.director, "Director One")
        XCTAssertEqual(sut.producer, "Producer One")
    }

    func testFetchCastAndCrewEmptyArrays() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            MovieCreditsResponse(cast: [], crew: [])
        }
        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchCastAndCrew(for: 1)

        // Then
        XCTAssertTrue(sut.cast.isEmpty)
        XCTAssertNil(sut.director)
        XCTAssertNil(sut.producer)
    }

    func testFetchMovieImagesSuccess() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            MovieImagesResponse(backdrops: [MovieImage(filePath: "/img.jpg")])
        }

        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchMovieImages(for: 1)

        // Then
        XCTAssertEqual(sut.images.count, 1)
        XCTAssertEqual(sut.images.first?.filePath, "/img.jpg")
    }

    func testFetchMovieImagesFailure() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            throw URLError(.timedOut)
        }
        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchMovieImages(for: 1)

        // Then
        XCTAssertTrue(sut.images.isEmpty)
    }
}
