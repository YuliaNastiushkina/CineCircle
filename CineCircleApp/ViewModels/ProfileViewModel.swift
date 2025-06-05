import SwiftUI

class ProfileViewModel: ObservableObject {
    /// The user's name. Changes to this property will automatically update views.
    @Published var name: String = ""
    /// The user's selected favorite genres. Changes to this property will automatically update views.
    @Published var favoriteGenres: [MoviesGenre] = []

    /// Initializes a new instance of `ProfileViewModel` and loads saved profile data from UserDefaults.
    init() {
        loadProfile()
    }

    /// Loads the user's profile data from UserDefaults. If no saved data is found, default values are used.
    func loadProfile() {
        name = UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name) ?? ""
        if let saved = UserDefaults.standard.array(forKey: ProfileUserDefaultsKeys.favoriteGenres) as? [String] {
            favoriteGenres = saved.compactMap { MoviesGenre(rawValue: $0) }
        }
    }

    /// Saves the profile data to UserDefaults only if the name is not empty.
    /// - Returns: A boolean indicating whether the save was successful.
    @discardableResult func saveProfile() -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        UserDefaults.standard.set(name, forKey: ProfileUserDefaultsKeys.name)
        let rawGenres = favoriteGenres.map(\.rawValue)
        UserDefaults.standard.set(rawGenres, forKey: ProfileUserDefaultsKeys.favoriteGenres)

        return true
    }
}
