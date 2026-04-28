/// Represents the response from the TMDB `/person/popular` endpoint.
struct PopularActorsResponse: Codable {
    /// Current page number.
    let page: Int
    /// List of fetched actors.
    let results: [RemoteActor]
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
