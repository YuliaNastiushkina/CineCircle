import Foundation

/// A movie that we fetch from the `api.themoviedb.org`.
struct RemoteMovie: Codable {
    /// Movie ID.
    let id: Int
    /// Movie title.
    let title: String
    /// A short description of the movie.
    let overview: String
    /// The relative path to the movie poster image.
    let posterPath: String?
    /// The average rating of the movie.
    let voteAverage: Double
    /// The release date of the movie in `"yyyy-MM-dd"` format.
    let releaseDate: String
    
    /// Fetches the list of top-rated movies from the TMDB API.
    /// 
    /// This method should perform a network request to the `/movie/top_rated` endpoint
    /// of `api.themoviedb.org` and decode the response into an array of `RemoteMovie`.
    /// 
    /// Example URL: `https://api.themoviedb.org/3/movie/top_rated?api_key=YOUR_API_KEY&language=en-US&page=1`
        func fetchTopRatedMovies() {
            // TODO: Implement API call and decoding logic.
        }}
