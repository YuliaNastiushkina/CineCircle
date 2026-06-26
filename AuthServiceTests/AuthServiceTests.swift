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
        try await auth.createAnAccount(email: "test@example.com", password: "12345678")

        XCTAssertEqual(auth.createdUsers["test@example.com"], "12345678")
        XCTAssertEqual(auth.signedInUserEmail, "test@example.com")
        XCTAssertEqual(auth.lastEmail, "test@example.com")
        XCTAssertEqual(auth.lastPassword, "12345678")
        XCTAssertEqual(auth.currentUser?.uid, "mockUserID")
    }

    func testCreateAccountDuplicateUserThrows() async throws {
        auth.createdUsers["test@example.com"] = "existing"

        do {
            try await auth.createAnAccount(email: "test@example.com", password: "newpassword")
            XCTFail("Expected error when creating a duplicate account")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MockAuth")
            XCTAssertEqual(nsError.code, 409)
            XCTAssertEqual(nsError.localizedDescription, "User already exists")
        }
    }

    func testCreateAccountReturnError() async throws {
        auth.shouldReturnError = true

        do {
            try await auth.createAnAccount(email: "test@example.com", password: "newpassword")
            XCTFail("Expected forced error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TestError")
            XCTAssertEqual(nsError.code, 1)
            XCTAssertEqual(nsError.localizedDescription, "Forced error")
        }
    }

    func testSignInSuccess() async throws {
        auth.createdUsers["test@example.com"] = "12345678"

        try await auth.signIn(email: "test@example.com", password: "12345678")

        XCTAssertEqual(auth.signedInUserEmail, "test@example.com")
        XCTAssertEqual(auth.lastEmail, "test@example.com")
        XCTAssertEqual(auth.lastPassword, "12345678")
        XCTAssertEqual(auth.currentUser?.isEmailVerified, true)
    }

    func testSignInWrongPasswordThrows() async throws {
        auth.createdUsers["test@example.com"] = "12345678"

        do {
            try await auth.signIn(email: "test@example.com", password: "qwerty")
            XCTFail("Expected invalid credentials")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MockAuth")
            XCTAssertEqual(nsError.code, 401)
            XCTAssertEqual(nsError.localizedDescription, "Invalid credentials")
        }
    }

    func testSignInForcedErrorThrows() async throws {
        auth.shouldReturnError = true

        do {
            try await auth.signIn(email: "test@example.com", password: "12345678")
            XCTFail("Expected forced error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TestError")
            XCTAssertEqual(nsError.code, 2)
            XCTAssertEqual(nsError.localizedDescription, "Forced error")
        }
    }

    func testPasswordResetRecordsEmail() async throws {
        try await auth.sendPasswordReset(email: "test@example.com")

        XCTAssertEqual(auth.passwordResetEmail, "test@example.com")
    }

    func testSendEmailVerificationRequiresCurrentUser() async throws {
        do {
            try await auth.sendEmailVerification()
            XCTFail("Expected missing user error")
        } catch {
            XCTAssertEqual(error as? AuthServiceError, .noCurrentUser)
        }
    }

    func testDeleteCurrentUserSuccess() async throws {
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: "mockUserID", email: "test@example.com", isEmailVerified: true)

        try await auth.deleteCurrentUser()

        XCTAssertTrue(auth.deletedCurrentUser)
        XCTAssertNil(auth.currentUser)
    }

    func testDeleteCurrentUserRequiresRecentLogin() async throws {
        auth.shouldRequireRecentLogin = true

        do {
            try await auth.deleteCurrentUser()
            XCTFail("Expected recent login error")
        } catch {
            XCTAssertEqual(error as? AuthServiceError, .requiresRecentLogin)
        }
    }

    func testSignOutResetsSignedUser() throws {
        auth.signedInUserEmail = "test@example.com"
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: "mockUserID", email: "test@example.com", isEmailVerified: true)

        try auth.signOut()

        XCTAssertNil(auth.signedInUserEmail)
        XCTAssertNil(auth.currentUser)
    }

    func testSignOutWhenAlreadySignedOutDoesNotThrow() {
        auth.signedInUserEmail = nil

        XCTAssertNoThrow(try auth.signOut())
        XCTAssertNil(auth.signedInUserEmail)
    }
}
