import Foundation

/// Represents the response from the TMDB `/movie/popular` endpoint.
struct MovieResponse: Decodable {
    /// List of fetched movies.
    let results: [RemoteMovie]
    /// Current page number.
    let page: Int
    /// Total number of results available.
    let totalResults: Int
    /// Total number of pages available.
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalResults = "total_results"
        case totalPages = "total_pages"
    }
}
