import Foundation

class MockAPIKeyProvider: APIKeyProvider {
    var apiKey: String?

    func getAPIKey() throws -> String {
        guard let key = apiKey else {
            throw NSError(domain: "API", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Key missing"])
        }
        return key
    }
}
