// swiftlint:disable all
@testable import CineCircle
import XCTest

@MainActor
final class AuthServiceTests: XCTestCase {
    private var auth: MockFirebaseAuth!

    override func setUp() {
        super.setUp()
        auth = MockFirebaseAuth()
    }

    func testCreateAnAccountSuccess() async throws {
        // When
        try await auth.createAnAccount(email: "test@example.com", password: "123456")

        // Then
        XCTAssertEqual(auth.createdUsers["test@example.com"], "123456")
        XCTAssertEqual(auth.signedInUserEmail, "test@example.com")
        XCTAssertEqual(auth.lastEmail, "test@example.com")
        XCTAssertEqual(auth.lastPassword, "123456")
    }

    func testCreateAccountDuplicateUserThrows() async throws {
        // Given
        auth.createdUsers["test@example.com"] = "existing"

        do {
            // When
            try await auth.createAnAccount(email: "test@example.com", password: "newpassword")
            XCTFail("Expected error when creating a duplicate account")
        } catch {
            // Then
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MockAuth")
            XCTAssertEqual(nsError.code, 409)
            XCTAssertEqual(nsError.localizedDescription, "User already exists")
        }
    }

    func testCreateAccountReturnError() async throws {
        // Given
        auth.shouldReturnError = true

        do {
            // When
            try await auth.createAnAccount(email: "test@example.com", password: "newpassword")
            XCTFail("Expected forced error")
        } catch {
            // Then
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TestError")
            XCTAssertEqual(nsError.code, 1)
            XCTAssertEqual(nsError.localizedDescription, "Forced error")
        }
    }

    func testSignInSuccess() async throws {
        // Given
        auth.createdUsers["test@example.com"] = "123456"

        // When
        try await auth.signIn(email: "test@example.com", password: "123456")

        // Then
        XCTAssertEqual(auth.signedInUserEmail, "test@example.com")
        XCTAssertEqual(auth.lastEmail, "test@example.com")
        XCTAssertEqual(auth.lastPassword, "123456")
    }

    func testSignInWrongPasswordThrows() async throws {
        // Given
        auth.createdUsers["test@example.com"] = "123456"

        do {
            // When
            try await auth.signIn(email: "test@example.com", password: "qwerty")
        } catch {
            // Then
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MockAuth")
            XCTAssertEqual(nsError.code, 401)
            XCTAssertEqual(nsError.localizedDescription, "Invalid credentials")
        }
    }

    func testSignInForcedErrorThrows() async throws {
        // Given
        auth.shouldReturnError = true

        do {
            // When
            try await auth.signIn(email: "test@example.com", password: "123456")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TestError")
            XCTAssertEqual(nsError.code, 2)
            XCTAssertEqual(nsError.localizedDescription, "Forced error")
        }
    }

    func testSignOutResetsSignedUser() throws {
        auth.signedInUserEmail = "test@example.com"
        try auth.signOut()
        XCTAssertNil(auth.signedInUserEmail)
    }

    func testSignOutWhenAlreadySignedOutDoesNotThrow() {
        auth.signedInUserEmail = nil

        XCTAssertNoThrow(try auth.signOut())
        XCTAssertNil(auth.signedInUserEmail)
    }
}
