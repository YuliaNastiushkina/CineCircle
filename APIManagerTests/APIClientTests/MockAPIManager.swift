import Foundation

class MockAPIManager: APIManager {
    override init(apiKey: String? = nil, keySource: APIKeySource) {
        super.init(apiKey: apiKey, keySource: keySource)
    }
}
