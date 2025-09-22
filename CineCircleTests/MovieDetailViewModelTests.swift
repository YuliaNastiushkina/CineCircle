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
                cast: [MovieCast(id: 1, name: "John Doe", profilePath: "/john.jpg")],
                crew: [MovieCrew(id: 1, name: "Margaret Wild", job: "Director", profilePath: "/margaret.jpg")]
            )
        }

        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchCastAndCrew(for: 1)

        // Then
        XCTAssertEqual(sut.cast.first?.name, "John Doe")
        XCTAssertEqual(sut.crew.first?.name, "Margaret Wild") // Fixed: was checking cast instead of crew
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
        XCTAssertNotNil(sut.errorMessage)
    }

    func testFetchCastAndCrewMultipleDirectorsProducers() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            MovieCreditsResponse(
                cast: [MovieCast(id: 1, name: "John Doe", profilePath: "/john.jpg")],
                crew: [
                    MovieCrew(id: 1, name: "Director One", job: "Director", profilePath: "/director1.jpg"),
                    MovieCrew(id: 2, name: "Producer One", job: "Producer", profilePath: "/producer1.jpg"),
                ]
            )
        }
        let sut = MovieDetailViewModel(client: mockClient)

        // When
        await sut.fetchCastAndCrew(for: 1)

        // Then
        let director = sut.crew.first { $0.job == "Director" }?.name
        let producer = sut.crew.first { $0.job == "Producer" }?.name

        XCTAssertEqual(director, "Director One")
        XCTAssertEqual(producer, "Producer One")
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
        XCTAssertTrue(sut.crew.isEmpty) // Added: also check crew is empty
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

    func testDetailsPresentationPopulatesFromModels() {
        // Given
        let vm = MovieDetailViewModel(client: MockAPIClient { _, _ in () as Any })
        vm.movieDetail = RemoteMovieDetail(
            id: 1,
            title: "T",
            overview: "O",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7.1,
            releaseDate: "2025-07-30",
            runtime: 89,
            originalLanguage: "en",
            genres: [.init(id: 1, name: "Sci‑Fi"), .init(id: 2, name: "Thriller")],
            productionCompanies: [.init(id: 1, name: "Universal Pictures"),
                                  .init(id: 2, name: "Bazeleves")]
        )
        vm.crew = [
            MovieCrew(id: 1, name: "Rich Lee", job: "Director", profilePath: nil),
            MovieCrew(id: 2, name: "Patrick Aiello", job: "Producer", profilePath: nil),
            MovieCrew(id: 3, name: "Kenny Golde", job: "Writer", profilePath: nil),
            MovieCrew(id: 4, name: "Marc Hyman", job: "Screenplay", profilePath: nil),
            MovieCrew(id: 5, name: "H.G. Wells", job: "Story", profilePath: nil),
        ]

        // When
        let details = vm.detailsPresentation

        // Then
        XCTAssertEqual(details.directors, "Rich Lee")
        XCTAssertEqual(details.producers, "Patrick Aiello")
        XCTAssertEqual(details.screenwriters, "H.G. Wells, Kenny Golde, Marc Hyman")
        XCTAssertEqual(details.productionCompanies, "Universal Pictures, Bazeleves")
        XCTAssertEqual(details.genres, "Sci‑Fi, Thriller")
        XCTAssertEqual(details.originalLanguage, "EN")
        XCTAssertEqual(details.releaseDate, "2025-07-30")
        XCTAssertEqual(details.runtime, "1h 29m")
    }

    func testDetailsPresentationHandlesMissingValues() {
        // Given
        let vm = MovieDetailViewModel(client: MockAPIClient { _, _ in () as Any })
        vm.movieDetail = RemoteMovieDetail(
            id: 1, title: "", overview: "", posterPath: nil, backdropPath: nil,
            voteAverage: 0, releaseDate: "", runtime: nil, originalLanguage: "",
            genres: [], productionCompanies: []
        )
        vm.crew = []

        // When
        let details = vm.detailsPresentation

        // Then
        XCTAssertEqual(details.directors, "—")
        XCTAssertEqual(details.producers, "—")
        XCTAssertEqual(details.screenwriters, "—")
        XCTAssertEqual(details.productionCompanies, "—")
        XCTAssertEqual(details.genres, "—")
        XCTAssertEqual(details.originalLanguage, "—")
        XCTAssertEqual(details.releaseDate, "—")
        XCTAssertEqual(details.runtime, "—")
    }
}
