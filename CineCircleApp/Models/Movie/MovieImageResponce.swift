/// Represents the response from TMDB API when fetching images for a movie.
struct MovieImagesResponse: Decodable {
    /// An array of backdrop images associated with the movie.
    let backdrops: [MovieImage]
}
