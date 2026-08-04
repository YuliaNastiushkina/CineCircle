import Foundation

/// Typed failures from recommendation intent generation.
enum MovieRecommendationError: Error, Equatable, LocalizedError {
    case emptyPrompt
    case missingResponseText
    case malformedResponse
    case invalidIntent

    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            "Enter what you want to watch."
        case .missingResponseText:
            "AI did not return a recommendation intent."
        case .malformedResponse:
            "AI returned an unreadable recommendation intent."
        case .invalidIntent:
            "AI returned an incomplete recommendation intent."
        }
    }
}
