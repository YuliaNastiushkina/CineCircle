// swiftlint:disable all
@testable import CineCircle
import XCTest

@MainActor
final class AuthServiceTests: XCTestCase {
    var auth: MockFirebaseAuth!

    override func setUp() {
        super.setUp()
        auth = MockFirebaseAuth()
    }

    func testCreateAnAccountSuccess() {
        let expectation = expectation(description: "Account creation should succeed")

        auth.createAnAccount(email: "test@example.com", password: "123456") { _, error in
            XCTAssertNil(error)
            XCTAssertEqual(self.auth.createdUsers["test@example.com"], "123456")
            XCTAssertEqual(self.auth.signedInUserEmail, "test@example.com")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testCreateAccountFailure() {
        auth.createdUsers["test@example.com"] = "123456"
        let expectation = expectation(description: "Duplicate account creation should fail")

        auth.createAnAccount(email: "test@example.com", password: "newpass") { _, error in
            XCTAssertNotNil(error)
            XCTAssertEqual((error! as NSError).code, 409)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testCreateAccountReturnError() {
        let auth = MockFirebaseAuth()
        auth.shouldReturnError = true

        let expectation = XCTestExpectation(description: "Error should be returned")

        auth.createAnAccount(email: "test@example.com", password: "123456") { result, error in
            XCTAssertNil(result)
            XCTAssertNotNil(error)
            XCTAssertEqual((error! as NSError).domain, "TestError")
            XCTAssertEqual((error! as NSError).code, 1)
            XCTAssertEqual(error?.localizedDescription, "Forced error")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSignInSuccess() {
        auth.createdUsers["test@example.com"] = "123456"
        let expectation = expectation(description: "Sign in should succeed")

        auth.signIn(email: "test@example.com", password: "123456") { _, error in
            XCTAssertNil(error)
            XCTAssertEqual(self.auth.signedInUserEmail, "test@example.com")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSignInWrongPasswordFails() {
        auth.createdUsers["test@example.com"] = "123456"
        let expectation = expectation(description: "Sign in failed")

        auth.signIn(email: "test@example.com", password: "qwerty") { _, error in
            XCTAssertNotNil(error)
            XCTAssertEqual((error! as NSError).code, 401)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSignInReturnErrorIfItAppear() {
        let auth = MockFirebaseAuth()
        auth.shouldReturnError = true

        let expectation = XCTestExpectation(description: "Error should be returned")

        auth.signIn(email: "test@example.com", password: "123456") { result, error in
            XCTAssertNil(result)
            XCTAssertNotNil(error)
            XCTAssertEqual((error! as NSError).domain, "TestError")
            XCTAssertEqual((error! as NSError).code, 2)
            XCTAssertEqual(error?.localizedDescription, "Forced error")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
