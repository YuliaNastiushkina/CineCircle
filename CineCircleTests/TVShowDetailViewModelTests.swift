@testable import CineCircle
import XCTest

@MainActor
final class TVShowDetailViewModelTests: XCTestCase {
    func testFetchShowAppendsRichMediaResponses() async {
        let expectedShow = RemoteTVShowDetail(
            id: 55,
            name: "Sample Show",
            overview: "Overview",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 8.5,
            voteCount: 100,
            firstAirDate: "2025-01-01",
            lastAirDate: nil,
            numberOfSeasons: 1,
            numberOfEpisodes: 8,
            episodeRunTime: [45],
            genres: [],
            seasons: [],
            tagline: "Sample tagline",
            status: "Returning Series"
        )
        let client = MockAPIClient { path, query in
            XCTAssertEqual(path, "tv/55")
            XCTAssertEqual(query["language"], "en-US")
            XCTAssertEqual(query["append_to_response"], "credits,videos,images")
            return expectedShow
        }
        let viewModel = TVShowDetailViewModel(client: client)

        await viewModel.fetchShow(id: 55)

        XCTAssertEqual(viewModel.show?.id, 55)
        XCTAssertEqual(viewModel.show?.tagline, "Sample tagline")
        XCTAssertEqual(viewModel.show?.status, "Returning Series")
    }
}
