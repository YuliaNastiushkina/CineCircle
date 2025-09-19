import Foundation

/// A movie crew member fetched from the `api.themoviedb.org`.
struct MovieCrew: Identifiable, Decodable {
    /// The unique identifier of the crew member.
    let id: Int
    /// The name of the crew member.
    let name: String
    /// The job title of the crew member (e.g., Director, Producer).
    let job: String
    /// Relative path to the crew member's image.
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case job
        case profilePath = "profile_path"
    }
}
