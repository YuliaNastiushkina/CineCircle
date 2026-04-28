import FirebaseAuth
import Foundation

/// Represents the current authentication state of the user.
enum AuthState {
    case undefined
    case authenticated(userId: String)
    case notAuthenticated
}

/// Tracks the current user's authentication state.
@MainActor
final class UserSession: ObservableObject {
    @Published var authState: AuthState = .undefined

    /// Initializes the user session and begins listening to authentication state changes.
    init() {
        listenToAuthChanges()
    }

    // MARK: Private interface

    private func listenToAuthChanges() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user {
                authState = .authenticated(userId: user.uid)
            } else {
                authState = .notAuthenticated
            }
        }
    }
}
