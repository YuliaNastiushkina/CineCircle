import Foundation

/// A singleton class responsible for managing the API key used in the application.
class APIManager {
    /// Shared instance of `APIManager`.
    static let shared = APIManager()
    /// The decoded API key. It is read-only from outside the class.
    private(set) var apiKey: String?
    /// Initializes the API manager and decodes the obfuscated API key.
    init() {
        decodeAPIKey()
    }

    /// Decodes the obfuscated API key using XOR with the provided salt and stores the result in `apiKey`.
    private func decodeAPIKey() {
        let decodedBytes = zip(APIKeys.obfuscatedKey, APIKeys.salt).map { $0 ^ $1 }
        apiKey = String(bytes: decodedBytes, encoding: .utf8)
    }
}
