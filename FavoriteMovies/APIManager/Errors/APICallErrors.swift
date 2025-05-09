import Foundation

/// Errors that may occur during an API call.
enum APICallError: Error, LocalizedError {
    case invalidResponse(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case let .invalidResponse(code):
            "Request failed with status code \(code)"
        }
    }
}
