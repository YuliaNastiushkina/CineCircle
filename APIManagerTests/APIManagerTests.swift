// swiftformat:disable trailing_whitespace
@testable import FavoriteMovies
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

        XCTAssertEqual(apiManager.apiKey, "")
    }
}
