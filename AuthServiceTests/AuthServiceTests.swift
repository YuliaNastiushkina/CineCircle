@testable import CineCircle
import XCTest

@MainActor
final class AuthServiceTests: XCTestCase {
    func testCreateAnAccountSuccess() {
        let mockAuthService = MockFirebaseAuth()
        let authService = AuthService(auth: mockAuthService)
        let expectation = expectation(description: "Completion called")

        authService.createAnAccount(email: "test@example.com", password: "123456") { error in
            XCTAssertNil(error)
            XCTAssertTrue(authService.signedIn)
            XCTAssertNil(authService.authError)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testCreateAccountFailure() {
        let mockAuthService = MockFirebaseAuth()
        mockAuthService.shouldReturnError = true
        let authService = AuthService(auth: mockAuthService)
        let expectation = expectation(description: "Completion called")

        authService.createAnAccount(email: "test@example.com", password: "123456") { error in
            XCTAssertNotNil(error)
            XCTAssertFalse(authService.signedIn)
            XCTAssertNotNil(authService.authError)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
