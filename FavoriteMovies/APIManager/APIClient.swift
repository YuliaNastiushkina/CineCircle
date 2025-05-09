import Foundation

/// A client for interacting with the TMDB API using an API key provided by `APIManager`.
///
/// Responsible for constructing requests, sending them, and decoding the responses.
/// It uses dependency injection for `APIManager`, which allows for easier testing and flexibility.
class APIClient {
    /// Provides the API key.
    private let keyManager: APIManager
    /// A session used to load data from the network.
    private let session: URLSession
    /// Initializes the `APIClient` with an optional custom API manager.
    ///
    /// - Parameters:
    ///   - keyManager: An object that manages the API key. Defaults to a shared `APIManager` instance.
    ///   - session: A custom `URLSession` to manage network requests. Defaults to `URLSession.shared`.
    init(keyManager: APIManager = APIManager(), session: URLSession = .shared) {
        self.keyManager = keyManager
        self.session = session
    }

    /// Fetches and decodes data from the TMDB API at a given path.
    ///
    /// This method builds the request URL using the path and query parameters, performs the request,
    /// and decodes the response into the provided type.
    /// - Parameters:
    ///   - path: The endpoint path after `/3/` (e.g., `"movie/popular"`).
    ///   - query: A dictionary of query parameters to include in the request (optional).
    ///   - responseType: The expected `Decodable` type of the response.
    /// - Returns: A decoded object of the specified type.
    /// - Throws: An error if the API key is missing, the URL is invalid, the network request fails,
    ///           or the decoding fails.
    func fetch<T: Decodable>(path: String, query: [String: String] = [:], responseType _: T.Type) async throws -> T {
        let key = try keyManager.getAPIKey()
        let url = try makeURL(path: path, query: query, apiKey: key)
        let data = try await loadData(from: url)
        return try decode(data, as: T.self)
    }

    /// Constructs a URL for the TMDB API using the provided path, query, and API key.
    /// - Parameters:
    ///   - path: The endpoint path after `/3/` (e.g., `"movie/popular"`).
    ///   - query: A dictionary of query parameters to include in the request (optional).
    ///   - apiKey: The API key to include in the query.
    /// - Returns: A valid `URL` object.
    /// - Throws: `URLError.badURL` if the URL could not be constructed.
    private func makeURL(path: String, query: [String: String], apiKey: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.themoviedb.org"
        components.path = "/3/\(path)"
        components.queryItems = ([("api_key", apiKey)] + query.map { ($0.key, $0.value) })
            .map { URLQueryItem(name: $0.0, value: $0.1) }

        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }

    /// Loads raw `Data` from the given URL using `URLSession`.
    /// - Parameter url: The `URL` to send the request to.
    /// - Returns: The raw `Data` from the response.
    /// - Throws: An error if the request fails or returns an invalid HTTP status code.
    private func loadData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw APICallError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    /// Decodes a `Decodable` type from the given `Data` using `JSONDecoder`.
    /// - Parameters:
    ///   - data: The raw JSON `Data` to decode.
    ///   - type: The expected `Decodable` type.
    /// - Returns: An instance of the decoded type.
    /// - Throws: An error if decoding fails.
    private func decode<T: Decodable>(_ data: Data, as _: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }
}
