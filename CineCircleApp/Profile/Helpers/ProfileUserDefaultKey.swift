import Foundation

/// Keys used for storing and retrieving user profile data from UserDefaults.
enum ProfileUserDefaultsKeys {
    static let name = "user_name"
    static let favoriteGenres = "user_favorite_genres"

    static func favoriteGenres(for userID: String) -> String {
        "\(favoriteGenres)_\(userID)"
    }
}

extension Notification.Name {
    static let profileFavoriteGenresDidChange = Notification.Name("profileFavoriteGenresDidChange")
}
