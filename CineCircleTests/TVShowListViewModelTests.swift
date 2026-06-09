@testable import CineCircle
import XCTest

@MainActor
final class TVShowListViewModelTests: XCTestCase {
    func testFetchAllShowsUsesDiscoverEndpoint() async {
        let client = MockAPIClient { path, query in
            XCTAssertEqual(path, "discover/tv")
            XCTAssertEqual(query["sort_by"], "popularity.desc")
            XCTAssertNil(query["with_genres"])
            return TVShowResponse(page: 1, results: [], totalResults: 0, totalPages: 1)
        }
        let viewModel = TVShowListViewModel(client: client)

        await viewModel.fetchAllShows()

        XCTAssertEqual(viewModel.selectedFilter, .all)
    }

    func testGenreFilterUsesDiscoverEndpoint() async {
        let client = MockAPIClient { path, query in
            XCTAssertEqual(path, "discover/tv")
            XCTAssertEqual(query["with_genres"], "18")
            return TVShowResponse(page: 1, results: [], totalResults: 0, totalPages: 1)
        }
        let viewModel = TVShowListViewModel(client: client)

        await viewModel.selectFilter(.genre(.drama))

        XCTAssertEqual(viewModel.selectedFilter, .genre(.drama))
    }

    func testFetchPopularShowsSuccess() async {
        let expectedShow = makeShow(id: 1, name: "Show One")
        let client = MockAPIClient { path, query in
            XCTAssertEqual(path, "tv/popular")
            XCTAssertEqual(query["language"], "en-US")
            XCTAssertEqual(query["page"], "1")
            return TVShowResponse(page: 1, results: [expectedShow], totalResults: 1, totalPages: 1)
        }
        let viewModel = TVShowListViewModel(client: client)

        await viewModel.fetchPopularShows()

        XCTAssertEqual(viewModel.shows.map(\.id), [1])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchPopularShowsFailure() async {
        let client = MockAPIClient { _, _ in
            throw URLError(.badServerResponse)
        }
        let viewModel = TVShowListViewModel(client: client)

        await viewModel.fetchPopularShows()

        XCTAssertTrue(viewModel.shows.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testPaginationLoadsNextPage() async {
        let firstShow = makeShow(id: 1, name: "Show One")
        let secondShow = makeShow(id: 2, name: "Show Two")
        let client = MockAPIClient { path, query in
            XCTAssertEqual(path, "tv/popular")
            if query["page"] == "1" {
                return TVShowResponse(page: 1, results: [firstShow], totalResults: 2, totalPages: 2)
            }
            return TVShowResponse(page: 2, results: [secondShow], totalResults: 2, totalPages: 2)
        }
        let viewModel = TVShowListViewModel(client: client)

        await viewModel.fetchPopularShows()
        await viewModel.fetchNextPageIfNeeded(currentShow: firstShow)

        XCTAssertEqual(viewModel.shows.map(\.id), [1, 2])
        XCTAssertEqual(viewModel.currentPage, 2)
    }

    func testSavedOnlyFiltersShows() {
        let viewModel = TVShowListViewModel()
        viewModel.shows = [
            makeShow(id: 1, name: "Show One"),
            makeShow(id: 2, name: "Show Two"),
        ]
        viewModel.savedIDs = [2]
        viewModel.showSavedOnly = true

        XCTAssertEqual(viewModel.displayedShows.map(\.id), [2])
    }

    func testSearchFiltersShowsByName() {
        let viewModel = TVShowListViewModel()
        viewModel.shows = [
            makeShow(id: 1, name: "Breaking Bad"),
            makeShow(id: 2, name: "The Bear"),
        ]

        viewModel.searchText = "bear"

        XCTAssertEqual(viewModel.displayedShows.map(\.id), [2])
    }

    private func makeShow(id: Int, name: String) -> RemoteTVShow {
        RemoteTVShow(
            id: id,
            name: name,
            overview: "",
            posterPath: nil,
            voteAverage: 8,
            voteCount: 100,
            firstAirDate: "2025-01-01",
            originalLanguage: "en",
            genreIDs: []
        )
    }
}
