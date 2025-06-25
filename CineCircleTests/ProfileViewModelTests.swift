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

        viewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
    }

    override func tearDown() {
        viewModel = nil
        userDefaults.removePersistentDomain(forName: "ProfileViewModelTests")
        super.tearDown()
    }

    func testSaveProfileSavesAndLoadsProfile() async throws {
        // Given
        viewModel.name = "Alice"
        viewModel.favoriteGenres = [.action, .comdey]

        // When
        viewModel.saveProfile()
        let newViewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
        await newViewModel.loadProfile()

        // Then
        XCTAssertEqual(newViewModel.name, "Alice")
        XCTAssertEqual(newViewModel.favoriteGenres, [.action, .comdey])
    }

    func testSaveProfileDoesNotSaveIfNameIsEmpty() async throws {
        // Given
        viewModel.name = ""
        viewModel.favoriteGenres = [.action, .comdey]

        // When
        let didSave = viewModel.saveProfile()

        // Then
        XCTAssertFalse(didSave, "Expected saveProfile to return false when name is empty")

        let reloadedViewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
        XCTAssertEqual(reloadedViewModel.name, "")
        XCTAssertEqual(reloadedViewModel.favoriteGenres, [])
    }

    func testSaveProfileOverrideExistingProfile() async throws {
        // Given
        viewModel.name = "Mary"
        viewModel.favoriteGenres = [.detective, .crime]
        viewModel.saveProfile()

        // When
        viewModel.name = "Kate"
        viewModel.favoriteGenres = [.detective, .historical]
        viewModel.saveProfile()

        // Then
        XCTAssertEqual(viewModel.name, "Kate")
        XCTAssertEqual(viewModel.favoriteGenres, [.detective, .historical])
    }
}
