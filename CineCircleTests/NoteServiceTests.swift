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
        sut.createOrUpdateNote(for: 1, userId: "testUser", content: "New note")

        // Then
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "New note")
    }

    func testCreateOrUpdateNoteUpdatesExistingNote() throws {
        // Given
        let _ = createTestNote()
        try context.save()

        // When
        sut.createOrUpdateNote(for: 1, userId: "testUser", content: "Updated content")

        // Then
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "Updated content")
    }

    func testCreateOrUpdateNoteHandlesEmptyContent() {
        // When
        sut.createOrUpdateNote(for: 1, userId: "testUser", content: "")

        // Then
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "")
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
