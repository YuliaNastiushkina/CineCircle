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

    func testCreateOrUpdateDiaryEntryCreatesTVEpisodeEntry() {
        // Given
        let watchedDate = Date(timeIntervalSince1970: 1_750_000_000)
        let target = MovieDiaryEntryTarget.tvEpisode(
            showId: 55,
            episodeId: 101,
            seasonNumber: 2,
            episodeNumber: 3
        )
        let draft = MovieDiaryEntryDraft(
            privateReflection: "The ending changed the whole season.",
            title: "The Long Night",
            parentTitle: "Example Show",
            watchedDate: watchedDate,
            watchType: .firstWatch,
            moods: [.awed, .unsettled],
            watchedWith: .friends,
            hasSpoilers: true
        )

        // When
        let error = sut.createOrUpdateDiaryEntry(
            for: target,
            userId: "testUser",
            draft: draft
        )

        // Then
        XCTAssertNil(error)
        XCTAssertTrue(sut.fetchNotes(for: 55, userId: "testUser").isEmpty)

        let entries = sut.fetchDiaryEntries(for: target, userId: "testUser")
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.mediaType, MovieDiaryMediaType.tvEpisode.rawValue)
        XCTAssertEqual(entries.first?.showID, 55)
        XCTAssertEqual(entries.first?.episodeID, 101)
        XCTAssertEqual(entries.first?.seasonNumber, 2)
        XCTAssertEqual(entries.first?.episodeNumber, 3)
        XCTAssertEqual(entries.first?.movieID, 0)
        XCTAssertEqual(entries.first?.movieTitle, "The Long Night")
        XCTAssertEqual(entries.first?.parentTitle, "Example Show")
        XCTAssertEqual(entries.first?.content, "The ending changed the whole season.")
        XCTAssertEqual(entries.first?.watchedDate, watchedDate)
        XCTAssertEqual(entries.first?.mood, "awed,unsettled")
        XCTAssertEqual(entries.first?.watchedWith, MovieDiaryWatchedWith.friends.rawValue)
        XCTAssertEqual(entries.first?.hasSpoilers, true)
    }

    func testCreateOrUpdateDiaryEntryUpdatesExistingTVEpisodeEntry() {
        // Given
        let target = MovieDiaryEntryTarget.tvEpisode(
            showId: 55,
            episodeId: 101,
            seasonNumber: 2,
            episodeNumber: 3
        )
        let firstDraft = MovieDiaryEntryDraft(
            privateReflection: "First reaction.",
            title: "Episode Three",
            parentTitle: "Example Show",
            watchedDate: Date(timeIntervalSince1970: 1_750_000_000),
            watchType: .firstWatch,
            moods: [.thoughtful],
            watchedWith: .alone,
            hasSpoilers: false
        )
        let updatedDate = Date(timeIntervalSince1970: 1_760_000_000)
        let updatedDraft = MovieDiaryEntryDraft(
            privateReflection: "I noticed more on rewatch.",
            title: "Episode Three",
            parentTitle: "Example Show",
            watchedDate: updatedDate,
            watchType: .rewatch,
            moods: [.haunted, .moved],
            watchedWith: .partner,
            hasSpoilers: true
        )

        // When
        XCTAssertNil(sut.createOrUpdateDiaryEntry(for: target, userId: "testUser", draft: firstDraft))
        let error = sut.createOrUpdateDiaryEntry(for: target, userId: "testUser", draft: updatedDraft)

        // Then
        XCTAssertNil(error)
        let entries = sut.fetchDiaryEntries(for: target, userId: "testUser")
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.content, "I noticed more on rewatch.")
        XCTAssertEqual(entries.first?.watchedDate, updatedDate)
        XCTAssertEqual(entries.first?.watchType, MovieDiaryWatchType.rewatch.rawValue)
        XCTAssertEqual(entries.first?.mood, "haunted,moved")
        XCTAssertEqual(entries.first?.watchedWith, MovieDiaryWatchedWith.partner.rawValue)
        XCTAssertEqual(entries.first?.hasSpoilers, true)
    }

    func testTVEpisodeDiaryEntryIDsReturnOnlyEntriesForShowAndUser() {
        // Given
        let firstTarget = MovieDiaryEntryTarget.tvEpisode(
            showId: 55,
            episodeId: 101,
            seasonNumber: 1,
            episodeNumber: 1
        )
        let secondTarget = MovieDiaryEntryTarget.tvEpisode(
            showId: 55,
            episodeId: 102,
            seasonNumber: 1,
            episodeNumber: 2
        )
        let otherShowTarget = MovieDiaryEntryTarget.tvEpisode(
            showId: 99,
            episodeId: 201,
            seasonNumber: 1,
            episodeNumber: 1
        )
        let draft = MovieDiaryEntryDraft(
            privateReflection: "A note.",
            title: "Episode",
            parentTitle: "Example Show",
            watchedDate: Date(timeIntervalSince1970: 1_750_000_000),
            watchType: .firstWatch,
            moods: [],
            watchedWith: .alone,
            hasSpoilers: false
        )

        // When
        XCTAssertNil(sut.createOrUpdateDiaryEntry(for: firstTarget, userId: "testUser", draft: draft))
        XCTAssertNil(sut.createOrUpdateDiaryEntry(for: secondTarget, userId: "testUser", draft: draft))
        XCTAssertNil(sut.createOrUpdateDiaryEntry(for: otherShowTarget, userId: "testUser", draft: draft))
        XCTAssertNil(sut.createOrUpdateDiaryEntry(for: firstTarget, userId: "otherUser", draft: draft))

        // Then
        XCTAssertEqual(sut.tvEpisodeDiaryEntryIDs(showId: 55, userId: "testUser"), [101, 102])
    }

    func testTVEpisodeDiaryDisplayUsesShowAndEpisodeCodeAsTitle() {
        // Given
        let target = MovieDiaryEntryTarget.tvEpisode(
            showId: 55,
            episodeId: 101,
            seasonNumber: 2,
            episodeNumber: 3
        )
        let draft = MovieDiaryEntryDraft(
            privateReflection: "A note.",
            title: "The Long Night",
            parentTitle: "Example Show",
            watchedDate: Date(timeIntervalSince1970: 1_750_000_000),
            watchType: .firstWatch,
            moods: [],
            watchedWith: .alone,
            hasSpoilers: false
        )

        // When
        XCTAssertNil(sut.createOrUpdateDiaryEntry(for: target, userId: "testUser", draft: draft))
        let entry = sut.fetchDiaryEntries(for: target, userId: "testUser").first

        // Then
        XCTAssertEqual(entry?.diaryDisplayTitle, "Example Show · S2 E3")
        XCTAssertEqual(entry?.diarySubtitle, "The Long Night")
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
