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
        clearDefaults(for: userID)
        clearDefaults(for: "otherUser")
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.name)
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.favoriteGenres)

        viewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
    }

    override func tearDown() {
        viewModel = nil
        clearDefaults(for: userID)
        clearDefaults(for: "otherUser")
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.name)
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.favoriteGenres)
        userDefaults.removePersistentDomain(forName: "ProfileViewModelTests")
        super.tearDown()
    }

    func testSaveProfileSavesAndLoadsProfile() async throws {
        viewModel.name = "Alice"
        viewModel.favoriteGenres = [.action, .comedy]

        viewModel.saveProfile()
        let newViewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
        await newViewModel.loadProfile()

        XCTAssertEqual(newViewModel.name, "Alice")
        XCTAssertEqual(newViewModel.favoriteGenres, [.action, .comedy])
    }

    func testSaveProfileDoesNotSaveIfNameIsEmpty() async throws {
        viewModel.name = ""
        viewModel.favoriteGenres = [.action, .comedy]

        let didSave = viewModel.saveProfile()

        XCTAssertFalse(didSave, "Expected saveProfile to return false when name is empty")

        let reloadedViewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
        await reloadedViewModel.loadProfile()
        XCTAssertEqual(reloadedViewModel.name, "")
        XCTAssertEqual(reloadedViewModel.favoriteGenres, [])
    }

    func testFavoriteGenresSaveWithoutProfileName() async {
        viewModel.name = ""
        viewModel.favoriteGenres = [.animation, .family]

        viewModel.saveFavoriteGenres()
        let reloadedViewModel = ProfileViewModel(userId: userID, authService: MockFirebaseAuth())
        await reloadedViewModel.loadProfile()

        XCTAssertEqual(reloadedViewModel.favoriteGenres, [.animation, .family])
        XCTAssertEqual(
            UserDefaults.standard.stringArray(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID)),
            ["animation", "family"]
        )
    }

    func testFavoriteGenresAreStoredPerUser() async {
        viewModel.favoriteGenres = [.action]
        viewModel.saveFavoriteGenres()
        let otherViewModel = ProfileViewModel(userId: "otherUser", authService: MockFirebaseAuth())

        await otherViewModel.loadProfile()

        XCTAssertTrue(otherViewModel.favoriteGenres.isEmpty)
    }

    func testShowsEmailVerificationReminderForUnverifiedEmail() async {
        let auth = MockFirebaseAuth()
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: userID, email: "test@example.com", isEmailVerified: false)
        let reminderViewModel = ProfileViewModel(userId: userID, authService: auth)

        await reminderViewModel.loadProfile()

        XCTAssertTrue(reminderViewModel.shouldShowEmailVerificationReminder)
        XCTAssertEqual(reminderViewModel.accountEmail, "test@example.com")
    }

    func testHidesEmailVerificationReminderForVerifiedEmail() async {
        let auth = MockFirebaseAuth()
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: userID, email: "test@example.com", isEmailVerified: true)
        let reminderViewModel = ProfileViewModel(userId: userID, authService: auth)

        await reminderViewModel.loadProfile()

        XCTAssertFalse(reminderViewModel.shouldShowEmailVerificationReminder)
    }

    func testRefreshAccountStatusReloadsFirebaseUserBeforeUpdatingReminder() async {
        let auth = MockFirebaseAuth()
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: userID, email: "test@example.com", isEmailVerified: false)
        let reminderViewModel = ProfileViewModel(userId: userID, authService: auth)

        await reminderViewModel.loadProfile()
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: userID, email: "test@example.com", isEmailVerified: true)
        await reminderViewModel.refreshAccountStatus()

        XCTAssertTrue(auth.didReloadCurrentUser)
        XCTAssertFalse(reminderViewModel.shouldShowEmailVerificationReminder)
    }

    func testResendEmailVerificationSendsEmailAndShowsStatus() async {
        let auth = MockFirebaseAuth()
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: userID, email: "test@example.com", isEmailVerified: false)
        let reminderViewModel = ProfileViewModel(userId: userID, authService: auth)

        await reminderViewModel.resendEmailVerification()

        XCTAssertTrue(auth.verificationEmailSent)
        XCTAssertEqual(reminderViewModel.verificationEmailStatus, .success("Verification email sent. Check your inbox."))
        XCTAssertEqual(reminderViewModel.errorMessage, "")
    }

    func testResendEmailVerificationDoesNotSendWhenAlreadyVerified() async {
        let auth = MockFirebaseAuth()
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: userID, email: "test@example.com", isEmailVerified: true)
        let reminderViewModel = ProfileViewModel(userId: userID, authService: auth)

        await reminderViewModel.resendEmailVerification()

        XCTAssertFalse(auth.verificationEmailSent)
        XCTAssertEqual(reminderViewModel.verificationEmailStatus, .success("Your email is already verified."))
    }

    func testProfileNameIsStoredPerUser() async {
        viewModel.name = "Alice"
        viewModel.saveProfile()
        let otherViewModel = ProfileViewModel(userId: "otherUser", authService: MockFirebaseAuth())

        await otherViewModel.loadProfile()

        XCTAssertEqual(UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name(for: userID)), "Alice")
        XCTAssertEqual(otherViewModel.name, "")
    }

    func testLegacyProfileNameMigratesToCurrentUser() async {
        UserDefaults.standard.set("Legacy Alice", forKey: ProfileUserDefaultsKeys.name)

        await viewModel.loadProfile()

        XCTAssertEqual(viewModel.name, "Legacy Alice")
        XCTAssertEqual(UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name(for: userID)), "Legacy Alice")
        XCTAssertNil(UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name))
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
        UserDefaults.standard.set(
            ["sci-fi", "historical", "detective"],
            forKey: ProfileUserDefaultsKeys.favoriteGenres
        )

        await viewModel.loadProfile()

        XCTAssertEqual(viewModel.favoriteGenres, [.scienceFiction, .history, .mystery])
        XCTAssertEqual(
            UserDefaults.standard.stringArray(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID)),
            ["science-fiction", "history", "mystery"]
        )
    }

    func testSaveProfileOverrideExistingProfile() async throws {
        viewModel.name = "Mary"
        viewModel.favoriteGenres = [.mystery, .crime]
        viewModel.saveProfile()

        viewModel.name = "Kate"
        viewModel.favoriteGenres = [.mystery, .history]
        viewModel.saveProfile()

        XCTAssertEqual(viewModel.name, "Kate")
        XCTAssertEqual(viewModel.favoriteGenres, [.mystery, .history])
    }

    func testDeleteAccountClearsUserSpecificLocalDataAfterFirebaseDelete() async {
        let auth = MockFirebaseAuth()
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: userID, email: "test@example.com", isEmailVerified: true)
        let cleanupService = UserLocalDataCleanupService(
            context: CoreDataManager(inMemory: true).context,
            defaults: .standard
        )
        let deletingViewModel = ProfileViewModel(
            userId: userID,
            authService: auth,
            localDataCleanupService: cleanupService
        )
        deletingViewModel.name = "Alice"
        deletingViewModel.favoriteGenres = [.action]
        deletingViewModel.saveProfile()
        UserDefaults.standard.set(Data(), forKey: "profile_image_\(userID)")
        UserDefaults.standard.set(Data(), forKey: "custom_lists_\(userID)")
        UserDefaults.standard.set(Data(), forKey: "tv_saved_shows_\(userID)")
        UserDefaults.standard.set([1, 2], forKey: "tv_watched_episodes_\(userID)_10")
        UserDefaults.standard.set("Other", forKey: ProfileUserDefaultsKeys.name(for: "otherUser"))

        await deletingViewModel.deleteAccount()

        XCTAssertTrue(auth.deletedCurrentUser)
        XCTAssertNil(UserDefaults.standard.object(forKey: ProfileUserDefaultsKeys.name(for: userID)))
        XCTAssertNil(UserDefaults.standard.object(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID)))
        XCTAssertNil(UserDefaults.standard.object(forKey: "profile_image_\(userID)"))
        XCTAssertNil(UserDefaults.standard.object(forKey: "custom_lists_\(userID)"))
        XCTAssertNil(UserDefaults.standard.object(forKey: "tv_saved_shows_\(userID)"))
        XCTAssertNil(UserDefaults.standard.object(forKey: "tv_watched_episodes_\(userID)_10"))
        XCTAssertEqual(UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name(for: "otherUser")), "Other")
    }

    func testDeleteAccountRequiresRecentLoginDoesNotClearLocalData() async {
        let auth = MockFirebaseAuth()
        auth.shouldRequireRecentLogin = true
        let cleanupService = UserLocalDataCleanupService(
            context: CoreDataManager(inMemory: true).context,
            defaults: .standard
        )
        let deletingViewModel = ProfileViewModel(
            userId: userID,
            authService: auth,
            localDataCleanupService: cleanupService
        )
        UserDefaults.standard.set("Alice", forKey: ProfileUserDefaultsKeys.name(for: userID))

        await deletingViewModel.deleteAccount()

        XCTAssertEqual(
            deletingViewModel.errorMessage,
            "Enter your password to confirm account deletion."
        )
        XCTAssertTrue(deletingViewModel.needsReauthentication)
        XCTAssertEqual(UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name(for: userID)), "Alice")
    }

    func testReauthenticationDeletesAccountAndClearsLocalData() async {
        let auth = MockFirebaseAuth()
        auth.shouldRequireRecentLogin = true
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: userID, email: "test@example.com", isEmailVerified: true)
        let cleanupService = UserLocalDataCleanupService(
            context: CoreDataManager(inMemory: true).context,
            defaults: .standard
        )
        let deletingViewModel = ProfileViewModel(
            userId: userID,
            authService: auth,
            localDataCleanupService: cleanupService
        )
        UserDefaults.standard.set("Alice", forKey: ProfileUserDefaultsKeys.name(for: userID))

        await deletingViewModel.deleteAccount()
        await deletingViewModel.reauthenticateAndDeleteAccount(password: "  exact password  ")

        XCTAssertEqual(auth.reauthenticatedPassword, "  exact password  ")
        XCTAssertTrue(auth.deletedCurrentUser)
        XCTAssertFalse(deletingViewModel.needsReauthentication)
        XCTAssertNil(UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name(for: userID)))
    }

    private func clearDefaults(for userID: String) {
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.name(for: userID))
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID))
        UserDefaults.standard.removeObject(forKey: "profile_image_\(userID)")
        UserDefaults.standard.removeObject(forKey: "custom_lists_\(userID)")
        UserDefaults.standard.removeObject(forKey: "tv_saved_shows_\(userID)")
        UserDefaults.standard.removeObject(forKey: "tv_seen_shows_\(userID)")
        for key in UserDefaults.standard.dictionaryRepresentation().keys
            where key.hasPrefix("tv_watched_episodes_\(userID)_")
            || key.hasPrefix("tv_watched_episodes_summary_\(userID)_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
