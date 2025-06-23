@testable import CineCircle
import CoreData
import XCTest

final class WatchedMovieServiceTests: XCTestCase {
    var sut: WatchedMovieService!
    var coreDataManager: CoreDataManager!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager(inMemory: true)
        context = coreDataManager.context
        sut = WatchedMovieService(context: context)
    }

    override func tearDown() {
        sut = nil
        coreDataManager = nil
        context = nil
        super.tearDown()
    }

    func testToggleWatchedCreatesWatchedMovieEntity() {
        // Given
        sut.toggleWatched(movieId: 10, userId: "userA")

        // When
        let request: NSFetchRequest<WatchedMovie> = WatchedMovie.fetchRequest()
        let results = try? context.fetch(request)

        // Then
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?.movieID, 10)
        XCTAssertEqual(results?.first?.userID, "userA")
    }

    func testIsWatchedReturnsFalseIfMovieNotMarkedAsWatched() {
        // When
        let result = sut.isWatched(movieId: 1, userId: "123a")

        // Then
        XCTAssertFalse(result)
    }

    func testIsWatchedReturnsTrueIfMovieMarkedAsWatched() {
        // Given
        sut.toggleWatched(movieId: 1, userId: "123a")

        // When
        let result = sut.isWatched(movieId: 1, userId: "123a")

        // Then
        XCTAssertTrue(result)
    }

    func testToggleWatchedTwiceRemoveEntry() {
        // Given
        sut.toggleWatched(movieId: 100, userId: "user123")
        XCTAssertTrue(sut.isWatched(movieId: 100, userId: "user123"))

        // When
        sut.toggleWatched(movieId: 100, userId: "user123")

        // Then
        XCTAssertFalse(sut.isWatched(movieId: 100, userId: "user123"))
    }

    func testMultipleUsersDoNotAffectEachOther() {
        sut.toggleWatched(movieId: 10, userId: "userA")

        XCTAssertTrue(sut.isWatched(movieId: 10, userId: "userA"))
        XCTAssertFalse(sut.isWatched(movieId: 10, userId: "userB"))
    }

    func testMultipleMoviesDoNotAffectEachOther() {
        sut.toggleWatched(movieId: 1, userId: "userA")

        XCTAssertTrue(sut.isWatched(movieId: 1, userId: "userA"))
        XCTAssertFalse(sut.isWatched(movieId: 2, userId: "userA"))
    }
}
