@testable import CineCircle
import XCTest

@MainActor
class ActorDetailsViewModelTests: XCTestCase {
    func testFetchActorDetailsSuccess() async {
        // Given
        let mockClient = MockAPIClient { path, _ in
            XCTAssertEqual(path, "person/42")
            return ActorDetails(
                id: 42,
                name: "Jane Doe",
                biography: "Some biography text",
                birthday: "1980-02-01",
                deathday: nil
            )
        }

        let viewModel = ActorDetailsViewModel(client: mockClient)

        // When
        await viewModel.fetchActorDetails(for: 42)

        // Then
        XCTAssertEqual(viewModel.biography, "Some biography text")
        XCTAssertEqual(viewModel.birthday, "1980-02-01")
        XCTAssertEqual(viewModel.deathday, nil)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchActorDetailsFailure() async {
        // Given
        let mockClient = MockAPIClient { _, _ in
            throw URLError(.timedOut)
        }

        let viewModel = ActorDetailsViewModel(client: mockClient)

        // When
        await viewModel.fetchActorDetails(for: 123)

        // Then
        XCTAssertTrue(viewModel.biography.isEmpty)
        XCTAssertNil(viewModel.birthday)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
