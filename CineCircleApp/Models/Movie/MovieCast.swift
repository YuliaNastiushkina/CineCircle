import Foundation

/// A movie cast member fetched from the `api.themoviedb.org`.
struct MovieCast: Identifiable, Decodable {
    /// The unique identifier of the actor.
    let id: Int
    /// The name of the actor.
    let name: String
}
