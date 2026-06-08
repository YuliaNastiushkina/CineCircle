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

        sut.toggle(movieId: 10, userId: "userA", title: "Movie 10", posterPath: "/10.jpg")

        let request: NSFetchRequest<WatchedMovie> = WatchedMovie.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.movieID, 10)
        XCTAssertEqual(results.first?.userID, "userA")
        XCTAssertEqual(results.first?.title, "Movie 10")
        XCTAssertEqual(results.first?.posterPath, "/10.jpg")
        XCTAssertTrue(sut.isSet(movieId: 10, userId: "userA"))
    }

    func testToggleTwiceRemovesRecord_Watched() throws {
        // Given
        let sut = MovieFlagService<WatchedMovie>(context: context)

        sut.toggle(movieId: 5, userId: "u1", title: "Movie 5", posterPath: nil)
        XCTAssertTrue(sut.isSet(movieId: 5, userId: "u1"))

        sut.toggle(movieId: 5, userId: "u1", title: "Movie 5", posterPath: nil)
        XCTAssertFalse(sut.isSet(movieId: 5, userId: "u1"))

        let request: NSFetchRequest<WatchedMovie> = WatchedMovie.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 0)
    }

    func testMultipleUsersIsolated_Watched() throws {
        let sut = MovieFlagService<WatchedMovie>(context: context)

        sut.toggle(movieId: 7, userId: "alice", title: "Movie 7", posterPath: nil)
        XCTAssertTrue(sut.isSet(movieId: 7, userId: "alice"))
        XCTAssertFalse(sut.isSet(movieId: 7, userId: "bob"))

        let request: NSFetchRequest<WatchedMovie> = WatchedMovie.fetchRequest()
        let all = try context.fetch(request)
        XCTAssertEqual(all.count, 1)
    }

    func testToggleCreatesRecord_Saved() throws {
        let sut = MovieFlagService<SavedMovie>(context: context)
        sut.toggle(movieId: 99, userId: "uX", title: "Movie 99", posterPath: nil)

        let request: NSFetchRequest<SavedMovie> = SavedMovie.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.movieID, 99)
        XCTAssertEqual(results.first?.userID, "uX")
        XCTAssertTrue(sut.isSet(movieId: 99, userId: "uX"))
    }

    func testToggleTwiceRemovesRecord_Saved() throws {
        let sut = MovieFlagService<SavedMovie>(context: context)
        sut.toggle(movieId: 3, userId: "uY", title: "Movie 3", posterPath: nil)
        sut.toggle(movieId: 3, userId: "uY", title: "Movie 3", posterPath: nil)

        XCTAssertFalse(sut.isSet(movieId: 3, userId: "uY"))

        let request: NSFetchRequest<SavedMovie> = SavedMovie.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 0)
    }
}
