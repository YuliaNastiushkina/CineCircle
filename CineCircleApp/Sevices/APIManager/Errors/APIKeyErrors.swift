import Foundation

/// Errors related to API key management.
enum APIKeyError: Error, LocalizedError, Equatable {
    case missingKey
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingKey: "API Key is missing"
        case .decodingFailed: "API Key decoding failed"
        }
    }
}
