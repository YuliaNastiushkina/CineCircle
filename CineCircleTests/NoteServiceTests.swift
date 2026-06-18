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
        let error = sut.createOrUpdateNote(
            for: 1,
            userId: "testUser",
            content: "New note",
            movieTitle: "Test Movie"
        )

        // Then
        XCTAssertNil(error)
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "New note")
        XCTAssertEqual(notes.first?.movieTitle, "Test Movie")
    }

    func testCreateOrUpdateNoteUpdatesExistingNote() throws {
        // Given
        let _ = createTestNote()
        try context.save()

        // When
        let error = sut.createOrUpdateNote(
            for: 1,
            userId: "testUser",
            content: "Updated content",
            movieTitle: "Updated Movie"
        )

        // Then
        XCTAssertNil(error)
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "Updated content")
        XCTAssertEqual(notes.first?.movieTitle, "Updated Movie")
    }

    func testCreateOrUpdateNoteHandlesEmptyContent() {
        // When
        let error = sut.createOrUpdateNote(
            for: 1,
            userId: "testUser",
            content: "",
            movieTitle: "Test Movie"
        )

        // Then
        XCTAssertNil(error)
        let notes = sut.fetchNotes(for: 1, userId: "testUser")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "")
    }

    func testCreateOrUpdateDiaryEntryCreatesEntryWithMetadata() {
        // Given
        let watchedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let draft = MovieDiaryEntryDraft(
            privateReflection: "This stayed with me.",
            movieTitle: "Past Lives",
            watchedDate: watchedDate,
            watchType: .rewatch,
            moods: [.moved, .thoughtful, .nostalgic],
            watchedWith: .partner,
            hasSpoilers: true
        )

        // When
        let error = sut.createOrUpdateDiaryEntry(
            for: 42,
            userId: "testUser",
            draft: draft
        )

        // Then
        XCTAssertNil(error)
        let entries = sut.fetchNotes(for: 42, userId: "testUser")
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.content, "This stayed with me.")
        XCTAssertEqual(entries.first?.movieTitle, "Past Lives")
        XCTAssertEqual(entries.first?.watchedDate, watchedDate)
        XCTAssertEqual(entries.first?.watchType, MovieDiaryWatchType.rewatch.rawValue)
        XCTAssertEqual(entries.first?.mood, "moved,thoughtful,nostalgic")
        XCTAssertEqual(entries.first?.watchedWith, MovieDiaryWatchedWith.partner.rawValue)
        XCTAssertEqual(entries.first?.hasSpoilers, true)
    }

    func testCreateOrUpdateDiaryEntryUpdatesExistingMetadata() throws {
        // Given
        let _ = createTestNote(movieId: 7, userId: "testUser")
        try context.save()
        let watchedDate = Date(timeIntervalSince1970: 1_800_000_000)
        let draft = MovieDiaryEntryDraft(
            privateReflection: "Changed my mind on rewatch.",
            movieTitle: "Arrival",
            watchedDate: watchedDate,
            watchType: .rewatch,
            moods: [.awed, .haunted],
            watchedWith: .friends,
            hasSpoilers: true
        )

        // When
        let error = sut.createOrUpdateDiaryEntry(
            for: 7,
            userId: "testUser",
            draft: draft
        )

        // Then
        XCTAssertNil(error)
        let entries = sut.fetchNotes(for: 7, userId: "testUser")
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.content, "Changed my mind on rewatch.")
        XCTAssertEqual(entries.first?.movieTitle, "Arrival")
        XCTAssertEqual(entries.first?.watchedDate, watchedDate)
        XCTAssertEqual(entries.first?.watchType, MovieDiaryWatchType.rewatch.rawValue)
        XCTAssertEqual(entries.first?.mood, "awed,haunted")
        XCTAssertEqual(entries.first?.watchedWith, MovieDiaryWatchedWith.friends.rawValue)
        XCTAssertEqual(entries.first?.hasSpoilers, true)
    }

    func testCreateOrUpdateNoteReturnsErrorWhenContextFailsToSave() {
        // Given
        let failingContext = FailingContext(concurrencyType: .mainQueueConcurrencyType)
        failingContext.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: CoreDataManager.shared.container.managedObjectModel)
        let service = NoteService(context: failingContext)

        // When
        let error = service.createOrUpdateNote(
            for: 1,
            userId: "testUser",
            content: "Will fail",
            movieTitle: "Test Movie"
        )

        // Then
        XCTAssertNotNil(error)
    }

    // MARK: - Helper Methods

    private func createTestNote(movieId: Int = 1, userId: String = "testUser") -> MovieDiary {
        let note = MovieDiary(context: context)
        note.movieID = Int32(movieId)
        note.userID = userId
        note.content = "Test note content"
        note.id = UUID()
        note.createdAt = Date()
        return note
    }
}

final class FailingContext: NSManagedObjectContext, @unchecked Sendable {
    override func save() throws {
        throw NSError(domain: "TestError", code: 999, userInfo: nil)
    }
}
