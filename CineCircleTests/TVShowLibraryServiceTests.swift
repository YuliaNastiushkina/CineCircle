@testable import CineCircle
import XCTest

final class TVShowLibraryServiceTests: XCTestCase {
    func testSavedAndSeenFlagsAreIndependent() throws {
        let suiteName = "TVShowLibraryServiceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = TVShowLibraryService(defaults: defaults)

        service.toggle(.saved, showID: 10, userID: "user", title: "Show", posterPath: nil)

        XCTAssertTrue(service.isSet(.saved, showID: 10, userID: "user"))
        XCTAssertFalse(service.isSet(.seen, showID: 10, userID: "user"))
    }

    func testFlagsAreIsolatedByUser() throws {
        let suiteName = "TVShowLibraryUserTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = TVShowLibraryService(defaults: defaults)

        service.toggle(.seen, showID: 10, userID: "userA", title: "Show", posterPath: nil)

        XCTAssertTrue(service.isSet(.seen, showID: 10, userID: "userA"))
        XCTAssertFalse(service.isSet(.seen, showID: 10, userID: "userB"))
    }

    func testToggleRemovesExistingFlag() throws {
        let suiteName = "TVShowLibraryToggleTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = TVShowLibraryService(defaults: defaults)

        service.toggle(.saved, showID: 10, userID: "user", title: "Show", posterPath: nil)
        service.toggle(.saved, showID: 10, userID: "user", title: "Show", posterPath: nil)

        XCTAssertFalse(service.isSet(.saved, showID: 10, userID: "user"))
    }
}
