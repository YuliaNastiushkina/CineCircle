@testable import CineCircle
import CoreData
import XCTest

final class MovieFlagServiceTests: XCTestCase {
    var coreDataManager: CoreDataManager!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager(inMemory: true)
        context = coreDataManager.context
    }

    override func tearDown() {
        context = nil
        coreDataManager = nil
        super.tearDown()
    }

    func testIsSetReturnsFalseWhenNoRecord_Watched() {
        let sut = MovieFlagService<WatchedMovie>(context: context)
        XCTAssertFalse(sut.isSet(movieId: 42, userId: "u1"))
    }

    func testToggleCreatesRecord_Watched() throws {
        let sut = MovieFlagService<WatchedMovie>(context: context)

        sut.toggle(movieId: 10, userId: "userA")

        let request: NSFetchRequest<WatchedMovie> = WatchedMovie.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.movieID, 10)
        XCTAssertEqual(results.first?.userID, "userA")
        XCTAssertTrue(sut.isSet(movieId: 10, userId: "userA"))
    }

    func testToggleTwiceRemovesRecord_Watched() throws {
        // Given
        let sut = MovieFlagService<WatchedMovie>(context: context)

        sut.toggle(movieId: 5, userId: "u1")
        XCTAssertTrue(sut.isSet(movieId: 5, userId: "u1"))

        sut.toggle(movieId: 5, userId: "u1")
        XCTAssertFalse(sut.isSet(movieId: 5, userId: "u1"))

        let request: NSFetchRequest<WatchedMovie> = WatchedMovie.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 0)
    }

    func testMultipleUsersIsolated_Watched() throws {
        let sut = MovieFlagService<WatchedMovie>(context: context)

        sut.toggle(movieId: 7, userId: "alice")
        XCTAssertTrue(sut.isSet(movieId: 7, userId: "alice"))
        XCTAssertFalse(sut.isSet(movieId: 7, userId: "bob"))

        let request: NSFetchRequest<WatchedMovie> = WatchedMovie.fetchRequest()
        let all = try context.fetch(request)
        XCTAssertEqual(all.count, 1)
    }

    func testToggleCreatesRecord_Saved() throws {
        let sut = MovieFlagService<SavedMovie>(context: context)
        sut.toggle(movieId: 99, userId: "uX")

        let request: NSFetchRequest<SavedMovie> = SavedMovie.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.movieID, 99)
        XCTAssertEqual(results.first?.userID, "uX")
        XCTAssertTrue(sut.isSet(movieId: 99, userId: "uX"))
    }

    func testToggleTwiceRemovesRecord_Saved() throws {
        let sut = MovieFlagService<SavedMovie>(context: context)
        sut.toggle(movieId: 3, userId: "uY")
        sut.toggle(movieId: 3, userId: "uY")

        XCTAssertFalse(sut.isSet(movieId: 3, userId: "uY"))

        let request: NSFetchRequest<SavedMovie> = SavedMovie.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 0)
    }
}
