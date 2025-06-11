/// Defines an API client capable of performing asynchronous network requests.
protocol APIClientProtocol {
    /// Performs an asynchronous network request to the given path with query parameters,
    /// and decodes the response into the specified `Decodable` type.
    /// - Parameters:
    ///   - path: The API endpoint path (relative to the base URL).
    ///   - query: A dictionary of query parameters to include in the request.
    ///   - responseType: The type to decode the response into.
    /// - Returns: A decoded object of the specified type.
    /// - Throws: An error if the request fails or decoding fails.
    func fetch<T: Decodable>(
        path: String,
        query: [String: String],
        responseType: T.Type
    ) async throws -> T
}
