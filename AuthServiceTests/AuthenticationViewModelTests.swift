// swiftlint:disable all
@testable import CineCircle
import FirebaseAuth
import XCTest

@MainActor
final class AuthenticationViewModelTests: XCTestCase {
    private var auth: MockFirebaseAuth!
    private var viewModel: AuthenticationViewModel!

    override func setUp() {
        super.setUp()
        auth = MockFirebaseAuth()
        viewModel = AuthenticationViewModel(authService: auth)
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.name(for: "mockUserID"))
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: ProfileUserDefaultsKeys.name(for: "mockUserID"))
        super.tearDown()
    }

    func testSignInNormalizesEmail() async {
        auth.createdUsers["test@example.com"] = "12345678"
        viewModel.email = "  TEST@Example.COM  "
        viewModel.password = "12345678"

        await viewModel.signIn()

        XCTAssertEqual(auth.lastEmail, "test@example.com")
        XCTAssertEqual(viewModel.errorMessage, "")
    }

    func testSignInAllowsUnverifiedEmailWithoutSigningOut() async {
        auth.createdUsers["test@example.com"] = "12345678"
        auth.currentUserMetadata = AuthenticatedUserMetadata(uid: "mockUserID", email: "test@example.com", isEmailVerified: false)
        viewModel.email = "test@example.com"
        viewModel.password = "12345678"

        await viewModel.signIn()

        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertEqual(auth.currentUser?.uid, "mockUserID")
        XCTAssertEqual(auth.currentUser?.isEmailVerified, false)
    }

    func testInvalidEmailShowsValidationMessage() async {
        viewModel.email = "not-an-email"
        viewModel.password = "12345678"

        await viewModel.signIn()

        XCTAssertEqual(viewModel.errorMessage, "Enter a valid email address.")
        XCTAssertNil(auth.lastEmail)
    }

    func testShortPasswordShowsValidationMessage() async {
        viewModel.email = "test@example.com"
        viewModel.password = "1234567"

        await viewModel.signIn()

        XCTAssertEqual(viewModel.errorMessage, "Password must be at least 8 characters.")
        XCTAssertNil(auth.lastEmail)
    }

    func testSignupRequiresNickname() async {
        viewModel.email = "test@example.com"
        viewModel.password = "12345678"

        await viewModel.createAnAccount()

        XCTAssertEqual(viewModel.errorMessage, "Enter a nickname with at least 2 characters.")
        XCTAssertNil(auth.lastEmail)
    }

    func testSignupSendsVerificationEmailStoresNicknameAndKeepsUserSignedIn() async {
        viewModel.nickname = " Cine Fan "
        viewModel.email = "test@example.com"
        viewModel.password = "12345678"

        await viewModel.createAnAccount()

        XCTAssertTrue(auth.verificationEmailSent)
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: ProfileUserDefaultsKeys.name(for: "mockUserID")),
            "Cine Fan"
        )
        XCTAssertEqual(auth.currentUser?.uid, "mockUserID")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.infoMessage, "Account created. Check your email when you have a moment to verify your address.")
        XCTAssertTrue(viewModel.didSendVerificationEmail)
        XCTAssertEqual(viewModel.errorMessage, "")
    }

    func testPasswordResetUsesNormalizedEmail() async {
        viewModel.email = "  TEST@Example.COM  "

        await viewModel.sendPasswordReset()

        XCTAssertEqual(auth.passwordResetEmail, "test@example.com")
        XCTAssertEqual(viewModel.infoMessage, "Password reset email sent. Check your inbox for the next step.")
    }

    func testPasswordResetRequiresValidEmail() async {
        viewModel.email = "test"

        await viewModel.sendPasswordReset()

        XCTAssertEqual(viewModel.errorMessage, "Enter a valid email address to reset your password.")
        XCTAssertNil(auth.passwordResetEmail)
    }

    func testRawProviderErrorIsMappedToSafeMessage() async {
        auth.shouldReturnError = true
        viewModel.email = "test@example.com"
        viewModel.password = "12345678"

        await viewModel.signIn()

        XCTAssertEqual(viewModel.errorMessage, "Something went wrong. Please try again.")
        XCTAssertFalse(viewModel.errorMessage.contains("Forced error"))
    }

    func testFirebaseWrongPasswordMapsToSafeCredentialMessage() async {
        let error = NSError(domain: "FIRAuthErrorDomain", code: AuthErrorCode.wrongPassword.rawValue)
        auth.shouldReturnError = true
        viewModel.email = "test@example.com"
        viewModel.password = "12345678"

        await viewModel.signIn()
        XCTAssertEqual(viewModel.errorMessage, "Something went wrong. Please try again.")
        XCTAssertNotEqual(error.localizedDescription, viewModel.errorMessage)
    }
}
