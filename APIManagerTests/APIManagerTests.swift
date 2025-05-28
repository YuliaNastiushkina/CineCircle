// swiftformat:disable trailing_whitespace
@testable import CineCircle
import XCTest

final class APIManagerTests: XCTestCase {
    func testAPIKeyDecodingWithMockedData() {
        let mockKey: [UInt8] = [0x41, 0x42, 0x43]
        let mockSalt: [UInt8] = [0x00, 0x00, 0x00]

        let mockSource = MockAPIKeys(obfuscatedKey: mockKey, salt: mockSalt)
        let apiManager = APIManager(keySource: mockSource)

        XCTAssertEqual(apiManager.apiKey, "ABC")
    }

    func testUnequalArrayLengths() {
        let mockKey: [UInt8] = [0x41, 0x42]
        let mockSalt: [UInt8] = [0x00, 0x00, 0x00]

        let mockSource = MockAPIKeys(obfuscatedKey: mockKey, salt: mockSalt)
        let apiManager = APIManager(keySource: mockSource)

        XCTAssertEqual(apiManager.apiKey, "AB")
    }

    func testInvalidUTF8Bytes() {
        let mockKey: [UInt8] = [0xFF, 0xFF, 0xFF]
        let mockSalt: [UInt8] = [0x00, 0x00, 0x00]

        let mockSource = MockAPIKeys(obfuscatedKey: mockKey, salt: mockSalt)
        let apiManager = APIManager(keySource: mockSource)

        XCTAssertNil(apiManager.apiKey)
    }

    func testEmptyArrays() {
        let mockSource = MockAPIKeys(obfuscatedKey: [], salt: [])
        let apiManager = APIManager(keySource: mockSource)

        XCTAssertEqual(apiManager.apiKey, nil)
    }

    func testGetAPIKeyThrowsWhenDecodingFails() {
        let invalidBytes: [UInt8] = [0xFF, 0xFF, 0xFF]
        let mockSource = MockAPIKeys(obfuscatedKey: invalidBytes, salt: [0x00, 0x00, 0x00])

        let apiManager = APIManager(keySource: mockSource)

        XCTAssertThrowsError(try apiManager.getAPIKey()) { error in
            XCTAssertEqual(error as? APIKeyError, .decodingFailed)
        }
    }

    func testGetAPIKeySucceedsWithMockedData() {
        // "ABC" = [0x41, 0x42, 0x43]
        let mockKey: [UInt8] = [0x41, 0x42, 0x43]
        let mockSalt: [UInt8] = [0x00, 0x00, 0x00]
        let mockSource = MockAPIKeys(obfuscatedKey: mockKey, salt: mockSalt)

        let apiManager = APIManager(keySource: mockSource)

        do {
            let key = try apiManager.getAPIKey()
            XCTAssertEqual(key, "ABC", "API Key should be correctly decoded")
        } catch {
            XCTFail("getAPIKey() should not throw when data is valid")
        }
    }
}
