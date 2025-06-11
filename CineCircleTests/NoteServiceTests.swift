@testable import CineCircle
import CoreData
import XCTest

final class NoteServiceTests: XCTestCase {
    var sut: NoteService!
    var coreDataManager: CoreDataManager!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager(inMemory: true)
        context = coreDataManager.context
        sut = NoteService(context: context)
    }

    override func tearDown() {
        sut = nil
        coreDataManager = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Fetch Notes Tests

    func testFetchNotesReturnsEmptyArrayWhenNoNotes() {
        // When
        let notes = sut.fetchNotes(for: 1, userId: "testUser")

        // Then
        XCTAssertTrue(notes.isEmpty)
    }

    func testFetchNotesReturnsCorrectNotes() throws {
        // Given
        let _ = createTestNote()
        try context.save()

        // When
        let notes = sut.fetchNotes(for: 1, userId: "testUser")

        // Then
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.movieID, 1)
        XCTAssertEqual(notes.first?.userID, "testUser")
        XCTAssertEqual(notes.first?.content, "Test note content")
    }

    func testCreateOrUpdateNoteCreatesNewNote() {
        // When
        let error = sut.createOrUpdateNote(for: 1, userId: "testUser", content: "New note")

        // Then
        XCTAssertNil(error)
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "New note")
    }

    func testCreateOrUpdateNoteUpdatesExistingNote() throws {
        // Given
        let _ = createTestNote()
        try context.save()

        // When
        let error = sut.createOrUpdateNote(for: 1, userId: "testUser", content: "Updated content")

        // Then
        XCTAssertNil(error)
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "Updated content")
    }

    func testCreateOrUpdateNoteHandlesEmptyContent() {
        // When
        let error = sut.createOrUpdateNote(for: 1, userId: "testUser", content: "")

        // Then
        XCTAssertNil(error)
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "")
    }

    func testCreateOrUpdateNoteReturnsErrorWhenContextFailsToSave() {
        // Given
        let failingContext = FailingContext(concurrencyType: .mainQueueConcurrencyType)
        failingContext.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: CoreDataManager.shared.container.managedObjectModel)
        let service = NoteService(context: failingContext)

        // When
        let error = service.createOrUpdateNote(for: 1, userId: "testUser", content: "Will fail")

        // Then
        XCTAssertNotNil(error)
    }

    // MARK: - Helper Methods

    private func createTestNote(movieId: Int = 1, userId: String = "testUser") -> MovieNote {
        let note = MovieNote(context: context)
        note.movieID = Int32(movieId)
        note.userID = userId
        note.content = "Test note content"
        note.id = UUID()
        note.createdAt = Date()
        return note
    }
}

final class FailingContext: NSManagedObjectContext {
    override func save() throws {
        throw NSError(domain: "TestError", code: 999, userInfo: nil)
    }
}
