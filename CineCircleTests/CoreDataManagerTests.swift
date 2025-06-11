@testable import CineCircle
import CoreData
import XCTest

final class CoreDataManagerTests: XCTestCase {
    var sut: CoreDataManager!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        sut = CoreDataManager(inMemory: true)
        context = sut.context
    }

    override func tearDown() {
        sut = nil
        context = nil
        super.tearDown()
    }

    func testNoteCreatesAndSave() throws {
        // Given
        let _ = createTestNote()

        // When
        sut.save()

        // Then
        let fetchRequest: NSFetchRequest<MovieNote> = MovieNote.fetchRequest()
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].movieID, 1)
        XCTAssertEqual(results[0].userID, "testUser")
        XCTAssertEqual(results[0].content, "This is a test note.")
    }

    func testNoteDeleted() throws {
        // Given
        let note = createTestNote()
        sut.save()

        // When
        sut.delete(item: note)
        let fetchRequest: NSFetchRequest<MovieNote> = MovieNote.fetchRequest()
        let results = try context.fetch(fetchRequest)

        // Then
        XCTAssertEqual(results.count, 0)
    }

    func testDeleteNonExistingNote() {
        // Given
        let fakeNote = MovieNote(context: context)
        fakeNote.id = UUID()

        // When
        sut.delete(item: fakeNote)

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func testNoteUpdatesSuccessfully() throws {
        // Given
        let note = createTestNote()
        sut.save()

        // When
        note.content = "Updated content"
        sut.save()

        // Then
        let fetchRequest: NSFetchRequest<MovieNote> = MovieNote.fetchRequest()
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "Updated content")
    }

    func testSaveDoesNothingIfNoChanges() {
        // Given
        // Do nothing

        // When
        sut.save()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Helper Methods

    private func createTestNote() -> MovieNote {
        let note = MovieNote(context: context)
        note.movieID = 1
        note.userID = "testUser"
        note.content = "This is a test note."
        note.id = UUID()
        note.createdAt = Date()
        return note
    }
}
