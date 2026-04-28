import Foundation

/// A movie cast member fetched from the `api.themoviedb.org`.
struct MovieCast: Identifiable, Decodable {
    /// The unique identifier of the actor.
    let id: Int
    /// The name of the actor.
    let name: String
    /// Relative path to the actor's image.
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
    }
}
