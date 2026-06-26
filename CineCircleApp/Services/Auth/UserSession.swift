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

    deinit {
        if let authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        }
    }

    func beginSignupPresentationDelay() {
        isDelayingSignupPresentation = true
        pendingAuthenticatedUserId = nil
    }

    func finishSignupPresentationDelay() {
        isDelayingSignupPresentation = false
        if let pendingAuthenticatedUserId {
            authState = .authenticated(userId: pendingAuthenticatedUserId)
            self.pendingAuthenticatedUserId = nil
        } else if let currentUser = Auth.auth().currentUser {
            authState = .authenticated(userId: currentUser.uid)
        }
    }

    func cancelSignupPresentationDelay() {
        isDelayingSignupPresentation = false
        pendingAuthenticatedUserId = nil
        authState = Auth.auth().currentUser.map { .authenticated(userId: $0.uid) } ?? .notAuthenticated
    }

    // MARK: Private interface

    private var isDelayingSignupPresentation = false
    private var pendingAuthenticatedUserId: String?
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    private func listenToAuthChanges() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user {
                if isDelayingSignupPresentation {
                    pendingAuthenticatedUserId = user.uid
                } else {
                    authState = .authenticated(userId: user.uid)
                }
            } else {
                pendingAuthenticatedUserId = nil
                authState = .notAuthenticated
            }
        }
    }
}
