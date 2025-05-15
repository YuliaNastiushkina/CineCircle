import Foundation

/// A response containing the cast and crew of a movie.
struct MovieCreditsResponse: Decodable {
    /// The list of cast members.
    let cast: [MovieCast]
    /// The list of crew members.
    let crew: [MovieCrew]
}
