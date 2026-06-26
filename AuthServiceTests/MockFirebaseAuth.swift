@testable import CineCircle
import Foundation

/// A mock implementation of `AuthServiceProtocol` used for unit testing.
class MockFirebaseAuth: AuthServiceProtocol {
    var createdUsers: [String: String] = [:]
    var signedInUserEmail: String?
    var shouldReturnError = false
    var shouldRequireRecentLogin = false
    var shouldDeleteCurrentUser = true
    var verificationEmailSent = false
    var reauthenticatedPassword: String?
    var shouldFailReauthentication = false
    var deletedCurrentUser = false
    var passwordResetEmail: String?
    var didReloadCurrentUser = false
    var currentUserMetadata: AuthenticatedUserMetadata?

    var currentUser: AuthenticatedUserMetadata? {
        currentUserMetadata
    }

    var lastEmail: String?
    var lastPassword: String?

    func createAnAccount(email: String, password: String) async throws {
        lastEmail = email
        lastPassword = password

        if shouldReturnError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Forced error"])
        }

        if createdUsers[email] != nil {
            throw NSError(domain: "MockAuth", code: 409, userInfo: [NSLocalizedDescriptionKey: "User already exists"])
        } else {
            createdUsers[email] = password
            signedInUserEmail = email
            currentUserMetadata = AuthenticatedUserMetadata(uid: "mockUserID", email: email, isEmailVerified: false)
        }
    }

    func signIn(email: String, password: String) async throws {
        lastEmail = email
        lastPassword = password

        if shouldReturnError {
            throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Forced error"])
        }

        if let storedPassword = createdUsers[email], storedPassword == password {
            signedInUserEmail = email
            let isEmailVerified = currentUserMetadata?.isEmailVerified ?? true
            currentUserMetadata = AuthenticatedUserMetadata(uid: "mockUserID", email: email, isEmailVerified: isEmailVerified)
        } else {
            throw NSError(domain: "MockAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
    }

    func sendPasswordReset(email: String) async throws {
        if shouldReturnError {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Forced error"])
        }
        passwordResetEmail = email
    }

    func sendEmailVerification() async throws {
        if shouldReturnError {
            throw NSError(domain: "TestError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Forced error"])
        }
        guard currentUserMetadata != nil else {
            throw AuthServiceError.noCurrentUser
        }
        verificationEmailSent = true
    }

    func reloadCurrentUser() async throws {
        guard currentUserMetadata != nil else {
            throw AuthServiceError.noCurrentUser
        }
        didReloadCurrentUser = true
    }

    func reauthenticateCurrentUser(password: String) async throws {
        if shouldFailReauthentication {
            throw NSError(domain: "MockAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid password"])
        }
        guard currentUserMetadata != nil else {
            throw AuthServiceError.noCurrentUser
        }
        reauthenticatedPassword = password
        shouldRequireRecentLogin = false
    }

    func deleteCurrentUser() async throws {
        if shouldRequireRecentLogin {
            throw AuthServiceError.requiresRecentLogin
        }

        if shouldReturnError {
            throw NSError(domain: "TestError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Forced error"])
        }

        guard shouldDeleteCurrentUser else {
            throw AuthServiceError.noCurrentUser
        }

        deletedCurrentUser = true
        signedInUserEmail = nil
        currentUserMetadata = nil
    }

    func signOut() throws {
        signedInUserEmail = nil
        currentUserMetadata = nil
    }
}
