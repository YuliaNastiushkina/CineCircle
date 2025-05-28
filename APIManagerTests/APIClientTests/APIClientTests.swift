// swiftformat:disable all
// swiftlint:disable all
@testable import CineCircle
import XCTest

final class APIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    
    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }
    
    func testFetchReturnsMockedData() async throws {
        let mockKey: [UInt8] = [0x41, 0x42, 0x43]
        let mockSalt: [UInt8] = [0x00, 0x00, 0x00]
        let mockSource = MockAPIKeys(obfuscatedKey: mockKey, salt: mockSalt)
        let apiManager = MockAPIManager(apiKey: "mock-api-key", keySource: mockSource)
        
        // swiftlint:disable:next non_optional_string_data_conversion
        let mockData = "{\"key\": \"value\"}".data(using: .utf8)
        MockURLProtocol.mockData = mockData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            // swiftlint:disable:next force_unwrapping
            url: URL(string: "https://api.themoviedb.org/3/movie/popular")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let apiClient = APIClient(keyManager: apiManager)
        let data = try await apiClient.fetch(path: "movie/popular", responseType: [String: String].self)
        
        XCTAssertEqual(data, ["key": "value"])
    }
    
    func testFetchThrowsErrorWhenAPIKeyMissing() async throws {
        let apiManager = MockAPIManager(apiKey: nil, keySource: MockAPIKeys(obfuscatedKey: [], salt: []))
        let apiClient = APIClient(keyManager: apiManager)

        do {
            _ = try await apiClient.fetch(path: "movie/popular", responseType: [String: String].self)
            XCTFail("Expected error, but fetch succeeded")
        } catch let error as APIKeyError {
            XCTAssertEqual(error, .missingKey)
        } 
    }

    func testFetchThrowsOnHTTPError() async throws {
        let apiManager = MockAPIManager(apiKey: "mock", keySource: MockAPIKeys(obfuscatedKey: [], salt: []))
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        let apiClient = APIClient(keyManager: apiManager, session: mockSession)

        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org/3/movie/popular")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )

        do {
            _ = try await apiClient.fetch(path: "movie/popular", responseType: [String: String].self)
            XCTFail("Expected error due to 404, but fetch succeeded")
        } catch let error as APICallError {
            switch error {
            case .invalidResponse(let code):
                XCTAssertEqual(code, 404)
            }
        }
    }
    
    func testFetchThrowsOnDecodingError() async {
        let apiManager = MockAPIManager(apiKey: "mock", keySource: MockAPIKeys(obfuscatedKey: [], salt: []))
        
        // swiftlint:disable:next non_optional_string_data_conversion
        let mockData = "not json".data(using: .utf8)
        MockURLProtocol.mockData = mockData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org/3/movie/popular")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let apiClient = APIClient(keyManager: apiManager)

        do {
            _ = try await apiClient.fetch(path: "movie/popular", responseType: [String: String].self)
            XCTFail("Expected decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}
