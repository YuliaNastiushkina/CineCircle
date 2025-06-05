@testable import CineCircle
import XCTest

@MainActor
class ActorListViewModelTests: XCTestCase {
    func testFetchPopularActorsSuccessed() async throws {
        // Given
        let expectedActors = [
            RemoteActor(id: 1, name: "Bob Keley", knownFor: [], profilePath: nil),
            RemoteActor(id: 2, name: "Dina Shaw", knownFor: [], profilePath: nil),
        ]

        let mockClient = MockAPIClient { path, _ in
            XCTAssertEqual(path, "person/popular")
            return PopularActorsResponse(
                page: 1,
                results: expectedActors,
                totalResults: 2,
                totalPages: 1
            )
        }

        let viewModel = ActorListViewModel(client: mockClient)
        // When
        await viewModel.fetchPopularActors()

        // Then
        XCTAssertEqual(viewModel.actors.count, expectedActors.count)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.currentPage, 1)
        XCTAssertEqual(viewModel.totalPages, 1)
    }

    func testFetchPopularActorsFailure() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            throw URLError(.badServerResponse)
        }
        let viewModel = ActorListViewModel(client: mockClient)

        // When
        await viewModel.fetchPopularActors()

        // Then
        XCTAssertTrue(viewModel.actors.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testFetchNextPageIfNeededLoadsMoreActors() async {
        // Given
        let pageOneActors = [RemoteActor(id: 1, name: "Actor One", knownFor: [], profilePath: nil)]
        let pageTwoActors = [RemoteActor(id: 2, name: "Actor Two", knownFor: [], profilePath: nil)]

        var page = 1
        let mockClient = MockAPIClient { _, query in
            if query["page"] == "1" {
                PopularActorsResponse(page: 1, results: pageOneActors, totalResults: 2, totalPages: 2)
            } else {
                PopularActorsResponse(page: 2, results: pageTwoActors, totalResults: 2, totalPages: 2)
            }
        }

        let viewModel = ActorListViewModel(client: mockClient)

        // When
        await viewModel.fetchPopularActors()
        await viewModel.fetchNextPageIfNeeded(currentActor: viewModel.actors.last!)

        // Then
        XCTAssertEqual(viewModel.actors.count, 2)
        XCTAssertEqual(viewModel.actors.map(\.id), [1, 2])
        XCTAssertNil(viewModel.errorMessage)
    }
}
