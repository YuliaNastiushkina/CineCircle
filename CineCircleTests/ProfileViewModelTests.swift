@testable import CineCircle
import Foundation
import XCTest

@MainActor
class ProfileViewModelTests: XCTestCase {
    var userDefaults: UserDefaults!
    var viewModel: ProfileViewModel!
    var userID: String = "testUserID"

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "ProfileViewModelTests")
        userDefaults.removePersistentDomain(forName: "ProfileViewModelTests")

        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.name)
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.favoriteGenres)
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID))

        viewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
    }

    override func tearDown() {
        viewModel = nil
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID))
        userDefaults.removePersistentDomain(forName: "ProfileViewModelTests")
        super.tearDown()
    }

    func testSaveProfileSavesAndLoadsProfile() async throws {
        // Given
        viewModel.name = "Alice"
        viewModel.favoriteGenres = [.action, .comedy]

        // When
        viewModel.saveProfile()
        let newViewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
        await newViewModel.loadProfile()

        // Then
        XCTAssertEqual(newViewModel.name, "Alice")
        XCTAssertEqual(newViewModel.favoriteGenres, [.action, .comedy])
    }

    func testSaveProfileDoesNotSaveIfNameIsEmpty() async throws {
        // Given
        viewModel.name = ""
        viewModel.favoriteGenres = [.action, .comedy]

        // When
        let didSave = viewModel.saveProfile()

        // Then
        XCTAssertFalse(didSave, "Expected saveProfile to return false when name is empty")

        let reloadedViewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
        XCTAssertEqual(reloadedViewModel.name, "")
        XCTAssertEqual(reloadedViewModel.favoriteGenres, [])
    }

    func testFavoriteGenresSaveWithoutProfileName() async {
        // Given
        viewModel.name = ""
        viewModel.favoriteGenres = [.animation, .family]

        // When
        viewModel.saveFavoriteGenres()
        let reloadedViewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
        await reloadedViewModel.loadProfile()

        // Then
        XCTAssertEqual(reloadedViewModel.favoriteGenres, [.animation, .family])
        XCTAssertEqual(
            UserDefaults.standard.stringArray(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID)),
            ["animation", "family"]
        )
    }

    func testFavoriteGenresAreStoredPerUser() async {
        // Given
        viewModel.favoriteGenres = [.action]
        viewModel.saveFavoriteGenres()
        let otherViewModel = ProfileViewModel(userId: "otherUser", authService: MockFirebaseAuth())

        // When
        await otherViewModel.loadProfile()

        // Then
        XCTAssertTrue(otherViewModel.favoriteGenres.isEmpty)
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: "otherUser"))
    }

    func testMovieGenresMatchTMDBCatalog() {
        let expectedGenres: [MoviesGenre: Int] = [
            .action: 28, .adventure: 12, .animation: 16, .comedy: 35,
            .crime: 80, .documentary: 99, .drama: 18, .family: 10751,
            .fantasy: 14, .history: 36, .horror: 27, .music: 10402,
            .mystery: 9648, .romance: 10749, .scienceFiction: 878,
            .tvMovie: 10770, .thriller: 53, .war: 10752, .western: 37,
        ]

        XCTAssertEqual(MoviesGenre.allCases.count, expectedGenres.count)
        for genre in MoviesGenre.allCases {
            XCTAssertEqual(genre.id, expectedGenres[genre])
        }
    }

    func testLoadProfileMigratesLegacyGenreValues() async {
        // Given
        UserDefaults.standard.set(
            ["sci-fi", "historical", "detective"],
            forKey: ProfileUserDefaultsKeys.favoriteGenres
        )

        // When
        await viewModel.loadProfile()

        // Then
        XCTAssertEqual(viewModel.favoriteGenres, [.scienceFiction, .history, .mystery])
        XCTAssertEqual(
            UserDefaults.standard.stringArray(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID)),
            ["science-fiction", "history", "mystery"]
        )
    }

    func testSaveProfileOverrideExistingProfile() async throws {
        // Given
        viewModel.name = "Mary"
        viewModel.favoriteGenres = [.mystery, .crime]
        viewModel.saveProfile()

        // When
        viewModel.name = "Kate"
        viewModel.favoriteGenres = [.mystery, .history]
        viewModel.saveProfile()

        // Then
        XCTAssertEqual(viewModel.name, "Kate")
        XCTAssertEqual(viewModel.favoriteGenres, [.mystery, .history])
    }
}
