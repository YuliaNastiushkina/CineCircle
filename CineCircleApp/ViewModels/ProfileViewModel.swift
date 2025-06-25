import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: Private interface

    /// A unique key used to store the user's name in UserDefaults.
    private let nameKey = ProfileUserDefaultsKeys.name
    /// A unique key used to store the user's favorite genres in UserDefaults.
    private let genresKey = ProfileUserDefaultsKeys.favoriteGenres
    private let authService: AuthServiceProtocol

    // MARK: Internal interface

    /// The ID of the currently authenticated user.
    /// Used to associate stored profile data (e.g., name, favorite genres) with a specific user.
    let userId: String

    /// Initializes a new instance of `ProfileViewModel`.
    /// This sets up the view model with the specified user ID and authentication service.
    /// - Parameter userId: The unique identifier for the user whose profile should be loaded and managed.
    /// - Parameter authService: The authentication service used to perform sign-in and account creation.
    init(userId: String, authService: AuthServiceProtocol) {
        self.userId = userId
        self.authService = authService
    }

    /// An error message displayed in the UI when logout fails or input is invalid.
    @Published var errorMessage = ""

    /// The user's name. Changes to this property will automatically update views.
    @Published var name: String = ""
    /// The user's selected favorite genres. Changes to this property will automatically update views.
    @Published var favoriteGenres: [MoviesGenre] = []

    /// Loads the user's profile data from UserDefaults. If no saved data is found, default values are used.
    func loadProfile() async {
        name = UserDefaults.standard.string(forKey: nameKey) ?? ""
        if let saved = UserDefaults.standard.array(forKey: genresKey) as? [String] {
            favoriteGenres = saved.compactMap { MoviesGenre(rawValue: $0) }
        }
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

        return true
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
