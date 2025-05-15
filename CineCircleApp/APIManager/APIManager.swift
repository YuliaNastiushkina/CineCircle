import Foundation

/// A singleton class responsible for managing the API key used in the application.
class APIManager: APIKeyProvider {
    /// The decoded API key. It is read-only from outside the class.
    private(set) var apiKey: String?
    /// The source of the obfuscated key and salt.
    private let keySource: APIKeySource
    /// Initializes the `APIManager` instance, optionally accepting a test API key or key source.
    ///
    /// - Parameters:
    ///   - apiKey: An optional string to use directly as the API key (useful for testing).
    ///   - keySource: A source of obfuscated key and salt. Defaults to `DefaultAPIKeys`.
    init(apiKey: String? = nil, keySource: APIKeySource = DefaultAPIKeys()) {
        self.keySource = keySource
        if let apiKey {
            self.apiKey = apiKey
        } else {
            decodeAPIKey()
        }
    }

    /// Decodes the obfuscated API key using XOR with the provided salt and stores the result in `apiKey`.
    private func decodeAPIKey() {
        let decodedBytes = zip(keySource.obfuscatedKey, keySource.salt).map { $0 ^ $1 }
        guard !decodedBytes.isEmpty else { return }
        apiKey = String(bytes: decodedBytes, encoding: .utf8)
    }

    /// Retrieves the API key, decoding it if necessary.
    /// - Returns: A valid API key string.
    /// - Throws:
    ///   - `APIKeyError.decodingFailed` if the decoding process fails.
    ///   - `APIKeyError.missingKey` if no API key is available and no valid data is provided for decoding.
    func getAPIKey() throws -> String {
        if apiKey == nil {
            guard !keySource.obfuscatedKey.isEmpty,
                  !keySource.salt.isEmpty else {
                throw APIKeyError.missingKey
            }
            decodeAPIKey()
            guard let decoded = apiKey, !decoded.isEmpty else {
                throw APIKeyError.decodingFailed
            }
        }
        guard let key = apiKey else {
            throw APIKeyError.missingKey
        }
        return key
    }
}
