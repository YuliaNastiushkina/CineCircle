import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: Private interface

    /// A unique key used to store the user's name in UserDefaults.
    private let nameKey = ProfileUserDefaultsKeys.name
    /// A unique key used to store the user's favorite genres in UserDefaults.
    private let genresKey = ProfileUserDefaultsKeys.favoriteGenres
    /// A unique key used to store the user's profile image in UserDefaults.
    private let profileImageKey: String
    private let authService: AuthServiceProtocol

    /// The user's profile image data
    @Published var profileImageData: Data?

    /// Movie statistics for the user
    @Published var movieStats = MovieStats()

    /// Movie IDs for navigation from stat cards
    @Published var watchedMovieIDs: [Int] = []
    @Published var savedMovieIDs: [Int] = []
    @Published var watchedMovies: [ProfileMovieSnapshot] = []
    @Published var savedMovies: [ProfileMovieSnapshot] = []
    @Published var libraryRefreshToken = UUID()

    private let statsService: MovieStatsService
    private let watchedService: WatchedMovieService
    private let savedService: SavedMovieService

    // MARK: Internal interface

    /// The ID of the currently authenticated user.
    /// Used to associate stored profile data (e.g., name, favorite genres) with a specific user.
    let userId: String

    /// Initializes a new instance of `ProfileViewModel`.
    /// This sets up the view model with the specified user ID and authentication service.
    /// - Parameter userId: The unique identifier for the user whose profile should be loaded and managed.
    /// - Parameter authService: The authentication service used to perform sign-in and account creation.
    init(
        userId: String,
        authService: AuthServiceProtocol,
        statsService: MovieStatsService = .shared,
        watchedService: WatchedMovieService = .shared,
        savedService: SavedMovieService = .shared
    ) {
        self.userId = userId
        self.authService = authService
        self.statsService = statsService
        self.watchedService = watchedService
        self.savedService = savedService
        profileImageKey = "profile_image_\(userId)"
    }

    /// An error message displayed in the UI when logout fails or input is invalid.
    @Published var errorMessage = ""

    /// The user's name. Changes to this property will automatically update views.
    @Published var name: String = ""
    /// The user's selected favorite genres. Changes to this property will automatically update views.
    @Published var favoriteGenres: [MoviesGenre] = []

    // Store original values for cancel functionality
    private var originalName: String = ""
    private var originalGenres: [MoviesGenre] = []
    private var originalProfileImageData: Data?

    /// Loads the user's profile data from UserDefaults. If no saved data is found, default values are used.
    func loadProfile() async {
        name = UserDefaults.standard.string(forKey: nameKey) ?? ""
        if let saved = UserDefaults.standard.array(forKey: genresKey) as? [String] {
            favoriteGenres = saved.compactMap { MoviesGenre(rawValue: $0) }
        }
        profileImageData = UserDefaults.standard.data(forKey: profileImageKey)
        loadStats()
        // Store original values for potential cancellation
        originalName = name
        originalGenres = favoriteGenres
        originalProfileImageData = profileImageData
    }

    /// Reverts changes back to the original loaded values
    func revertChanges() {
        name = originalName
        favoriteGenres = originalGenres
        profileImageData = originalProfileImageData
    }

    /// Saves the profile data to UserDefaults only if the name is not empty.
    /// - Returns: A boolean indicating whether the save was successful.
    @discardableResult func saveProfile() -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        UserDefaults.standard.set(name, forKey: nameKey)
        let rawGenres = favoriteGenres.map(\.rawValue)
        UserDefaults.standard.set(rawGenres, forKey: genresKey)

        // Save profile image if available
        if let imageData = profileImageData {
            UserDefaults.standard.set(imageData, forKey: profileImageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: profileImageKey)
        }

        // Update original values after successful save
        originalName = name
        originalGenres = favoriteGenres
        originalProfileImageData = profileImageData

        return true
    }

    /// Sets the profile image from a UIImage
    func setProfileImage(_ image: UIImage?) {
        if let image {
            // Resize image to reasonable size to save storage
            let targetSize = CGSize(width: 200, height: 200)
            let resizedImage = image.resized(to: targetSize)
            profileImageData = resizedImage?.jpegData(compressionQuality: 0.8)
        } else {
            profileImageData = nil
        }
    }

    /// Gets the profile image as UIImage
    var profileImage: UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }

    /// Refreshes movie stats and IDs from Core Data.
    func loadStats() {
        movieStats = statsService.calculateStats(for: userId)
        watchedMovieIDs = watchedService.allWatchedMovieIDs(for: userId)
        savedMovieIDs = savedService.allSavedMovieIDs(for: userId)
        watchedMovies = watchedService.allWatchedMovies(for: userId)
        savedMovies = savedService.allSavedMovies(for: userId)
        libraryRefreshToken = UUID()
    }

    func signOut() {
        do {
            try authService.signOut()
            errorMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
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
