import FirebaseAuth

/// A concrete implementation of `AuthServiceProtocol` that uses Firebase Authentication.
final class FirebaseAuthService: AuthServiceProtocol {
    var currentUser: AuthenticatedUserMetadata? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AuthenticatedUserMetadata(
            uid: user.uid,
            email: user.email,
            isEmailVerified: user.isEmailVerified
        )
    }

    func createAnAccount(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.noCurrentUser
        }
        try await user.sendEmailVerification()
    }

    func reloadCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.noCurrentUser
        }
        try await user.reload()
    }

    func reauthenticateCurrentUser(password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.noCurrentUser
        }
        guard let email = user.email else {
            throw AuthServiceError.missingEmail
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }

    func deleteCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.noCurrentUser
        }

        do {
            try await user.delete()
        } catch {
            if (error as NSError).code == AuthErrorCode.requiresRecentLogin.rawValue {
                throw AuthServiceError.requiresRecentLogin
            }
            throw error
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
