import Foundation

struct AuthenticatedUserMetadata: Equatable {
    let uid: String
    let email: String?
    let isEmailVerified: Bool
}

/// An abstraction over authentication services. Provides account management functions without exposing provider details to UI.
protocol AuthServiceProtocol {
    var currentUser: AuthenticatedUserMetadata? { get }

    func createAnAccount(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func sendPasswordReset(email: String) async throws
    func sendEmailVerification() async throws
    func reloadCurrentUser() async throws
    func reauthenticateCurrentUser(password: String) async throws
    func deleteCurrentUser() async throws
    func signOut() throws
}

enum AuthServiceError: Error, Equatable {
    case noCurrentUser
    case missingEmail
    case requiresRecentLogin
}
