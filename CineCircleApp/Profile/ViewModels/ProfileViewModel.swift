import FirebaseAuth
import SwiftUI

enum VerificationEmailStatus: Equatable {
    case success(String)
    case failure(String)

    var message: String {
        switch self {
        case let .success(message), let .failure(message):
            message
        }
    }

    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    private let nameKey: String
    private let genresKey: String
    private let profileImageKey: String
    private let authService: AuthServiceProtocol
    private let statsService: MovieStatsService
    private let watchedService: WatchedMovieService
    private let savedService: SavedMovieService
    private let localDataCleanupService: UserLocalDataCleanupService

    @Published var profileImageData: Data?
    @Published var movieStats = MovieStats()
    @Published var watchedMovieIDs: [Int] = []
    @Published var savedMovieIDs: [Int] = []
    @Published var watchedMovies: [ProfileMovieSnapshot] = []
    @Published var savedMovies: [ProfileMovieSnapshot] = []
    @Published var seenTVShows: [TVShowLibraryRecord] = []
    @Published var savedTVShows: [TVShowLibraryRecord] = []
    @Published var trackedTVShows: [TVShowProgressRecord] = []
    @Published var libraryRefreshToken = UUID()
    @Published var errorMessage = ""
    @Published var isDeletingAccount = false
    @Published var needsReauthentication = false
    @Published var isSendingVerificationEmail = false
    @Published var verificationEmailStatus: VerificationEmailStatus?
    @Published var accountEmail: String?
    @Published var isEmailVerified = true
    @Published var name: String = ""
    @Published var favoriteGenres: [MoviesGenre] = []

    let userId: String

    init(
        userId: String,
        authService: AuthServiceProtocol,
        statsService: MovieStatsService = .shared,
        watchedService: WatchedMovieService = .shared,
        savedService: SavedMovieService = .shared,
        localDataCleanupService: UserLocalDataCleanupService = .shared
    ) {
        self.userId = userId
        self.authService = authService
        self.statsService = statsService
        self.watchedService = watchedService
        self.savedService = savedService
        self.localDataCleanupService = localDataCleanupService
        nameKey = ProfileUserDefaultsKeys.name(for: userId)
        genresKey = ProfileUserDefaultsKeys.favoriteGenres(for: userId)
        profileImageKey = "profile_image_\(userId)"
    }

    private var originalName: String = ""
    private var originalGenres: [MoviesGenre] = []
    private var originalProfileImageData: Data?

    func loadProfile() async {
        refreshAuthMetadata()
        migrateLegacyNameIfNeeded()

        name = UserDefaults.standard.string(forKey: nameKey) ?? ""
        let saved = UserDefaults.standard.stringArray(forKey: genresKey)
            ?? UserDefaults.standard.stringArray(forKey: ProfileUserDefaultsKeys.favoriteGenres)
            ?? []
        favoriteGenres = saved.compactMap(MoviesGenre.fromStoredValue)
        let migratedValues = favoriteGenres.map(\.rawValue)
        UserDefaults.standard.set(migratedValues, forKey: genresKey)
        profileImageData = UserDefaults.standard.data(forKey: profileImageKey)
        loadStats()
        originalName = name
        originalGenres = favoriteGenres
        originalProfileImageData = profileImageData
    }

    func revertChanges() {
        name = originalName
        favoriteGenres = originalGenres
        profileImageData = originalProfileImageData
    }

    @discardableResult func saveProfile() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return false
        }

        UserDefaults.standard.set(trimmedName, forKey: nameKey)
        name = trimmedName
        saveFavoriteGenres()

        if let imageData = profileImageData {
            UserDefaults.standard.set(imageData, forKey: profileImageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: profileImageKey)
        }

        originalName = name
        originalGenres = favoriteGenres
        originalProfileImageData = profileImageData

        return true
    }

    func saveFavoriteGenres() {
        let rawGenres = favoriteGenres.map(\.rawValue)
        UserDefaults.standard.set(rawGenres, forKey: genresKey)
        originalGenres = favoriteGenres
        NotificationCenter.default.post(
            name: .profileFavoriteGenresDidChange,
            object: nil,
            userInfo: ["userID": userId]
        )
    }

    func setProfileImage(_ image: UIImage?) {
        if let image {
            let targetSize = CGSize(width: 200, height: 200)
            let resizedImage = image.resized(to: targetSize)
            profileImageData = resizedImage?.jpegData(compressionQuality: 0.8)
        } else {
            profileImageData = nil
        }
    }

    var profileImage: UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }

    func refreshAccountStatus() async {
        try? await authService.reloadCurrentUser()
        refreshAuthMetadata()
    }

    func clearVerificationEmailStatus() {
        verificationEmailStatus = nil
    }

    func resendEmailVerification() async {
        guard !isSendingVerificationEmail else { return }
        isSendingVerificationEmail = true
        verificationEmailStatus = nil
        defer { isSendingVerificationEmail = false }

        do {
            try? await authService.reloadCurrentUser()
            refreshAuthMetadata()

            guard !isEmailVerified else {
                verificationEmailStatus = .success("Your email is already verified.")
                errorMessage = ""
                return
            }

            try await authService.sendEmailVerification()
            verificationEmailStatus = .success("Verification email sent. Check your inbox.")
            errorMessage = ""
        } catch AuthServiceError.noCurrentUser {
            verificationEmailStatus = .failure("We could not find an active account session. Please sign in again.")
        } catch {
            verificationEmailStatus = .failure(friendlyVerificationEmailMessage(for: error))
        }
    }

    func loadStats() {
        refreshAuthMetadata()
        movieStats = statsService.calculateStats(for: userId)
        watchedMovieIDs = watchedService.allWatchedMovieIDs(for: userId)
        savedMovieIDs = savedService.allSavedMovieIDs(for: userId)
        watchedMovies = watchedService.allWatchedMovies(for: userId)
        savedMovies = savedService.allSavedMovies(for: userId)
        let tvLibrary = TVShowLibraryService()
        seenTVShows = tvLibrary.records(.seen, userID: userId)
        savedTVShows = tvLibrary.records(.saved, userID: userId)
        trackedTVShows = TVEpisodeProgressService().trackedShows(userID: userId)
        libraryRefreshToken = UUID()
    }

    func signOut() {
        do {
            try authService.signOut()
            errorMessage = ""
        } catch {
            errorMessage = "We could not sign you out. Please try again."
        }
    }

    func deleteAccount() async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await authService.deleteCurrentUser()
            localDataCleanupService.deleteLocalData(for: userId)
            needsReauthentication = false
            errorMessage = ""
        } catch AuthServiceError.requiresRecentLogin {
            needsReauthentication = true
            errorMessage = "Enter your password to confirm account deletion."
        } catch AuthServiceError.noCurrentUser {
            errorMessage = "We could not find an active account session. Please sign in again."
        } catch {
            errorMessage = "We could not delete your account. Please try again."
        }
    }

    func reauthenticateAndDeleteAccount(password: String) async {
        guard !password.isEmpty else {
            errorMessage = "Enter your password to confirm account deletion."
            needsReauthentication = true
            return
        }

        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await authService.reauthenticateCurrentUser(password: password)
            try await authService.deleteCurrentUser()
            localDataCleanupService.deleteLocalData(for: userId)
            needsReauthentication = false
            errorMessage = ""
        } catch AuthServiceError.noCurrentUser {
            errorMessage = "We could not find an active account session. Please sign in again."
        } catch AuthServiceError.missingEmail {
            errorMessage = "This account does not have an email address available for password confirmation."
        } catch AuthServiceError.requiresRecentLogin {
            needsReauthentication = true
            errorMessage = "Enter your password again to confirm account deletion."
        } catch {
            errorMessage = friendlyAccountDeletionMessage(for: error)
        }
    }

    var shouldShowEmailVerificationReminder: Bool {
        accountEmail != nil && !isEmailVerified
    }

    private func friendlyVerificationEmailMessage(for error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many verification emails were requested. Please wait a few minutes and try again."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection and try again."
        default:
            return "We could not send the verification email. Please try again."
        }
    }

    private func friendlyAccountDeletionMessage(for error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            needsReauthentication = true
            return "The password is incorrect."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection and try again."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please wait a moment and try again."
        default:
            return "We could not delete your account. Please try again."
        }
    }

    private func refreshAuthMetadata() {
        accountEmail = authService.currentUser?.email
        isEmailVerified = authService.currentUser?.isEmailVerified ?? true
    }

    private func migrateLegacyNameIfNeeded() {
        guard UserDefaults.standard.string(forKey: nameKey) == nil,
              let legacyName = UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name),
              !legacyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        UserDefaults.standard.set(legacyName, forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.name)
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage? {
        let size = size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
