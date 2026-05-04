import Foundation

/// A response containing all videos associated with a movie.
struct MovieVideosResponse: Decodable {
    /// The list of video entries returned by TMDB.
    let results: [MovieVideo]
}
