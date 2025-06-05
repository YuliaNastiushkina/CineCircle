@testable import CineCircle
import XCTest

@MainActor
class ActorDetailsViewModelTests: XCTestCase {
    func testFetchActorDetailsSuccess() async {
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
        await viewModel.fetchActorDetails(for: 42)

        XCTAssertEqual(viewModel.biography, "Some biography text")
        XCTAssertEqual(viewModel.birthday, "1980-02-01")
        XCTAssertEqual(viewModel.deathday, nil)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchActorDetailsFailure() async {
        let mockClient = MockAPIClient { _, _ in
            throw URLError(.timedOut)
        }

        let viewModel = ActorDetailsViewModel(client: mockClient)
        await viewModel.fetchActorDetails(for: 123)

        XCTAssertTrue(viewModel.biography.isEmpty)
        XCTAssertNil(viewModel.birthday)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

/// A mock implementation of `APIClientProtocol` for unit testing.
/// Uses a user-defined closure to return test responses or simulate failures.
struct MockAPIClient: APIClientProtocol {
    /// A closure that simulates the network call. It receives the request path and query parameters,
    /// and returns a value that will be cast to the expected decoded type.
    let fetchHandler: (String, [String: String]) async throws -> Any

    /// Simulates fetching a network response using the `fetchHandler`.
    ///
    /// - Parameters:
    ///   - path: The simulated API path.
    ///   - query: The simulated query parameters.
    ///   - responseType: The expected return type for decoding.
    /// - Returns: A decoded object of the expected type.
    /// - Throws: An error if the handler throws or the type cast fails.
    func fetch<T: Decodable>(
        path: String,
        query: [String: String],
        responseType _: T.Type
    ) async throws -> T {
        guard let result = try await fetchHandler(path, query) as? T else {
            fatalError("Mock returned unexpected type \(T.self)")
        }
        return result
    }
}
