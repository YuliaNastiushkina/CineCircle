import Foundation

/// Defines an object capable of providing an API key.
///
/// This abstraction allows `APIClient` to depend on any type that can supply an API key,
/// which is useful for testing and flexibility (e.g., mock API keys in unit tests).
protocol APIKeyProvider {
    /// Returns an API key as a `String`.
    ///
    /// - Returns: The API key.
    func getAPIKey() throws -> String
}
