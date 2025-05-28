import FirebaseAuth
import FirebaseCore
import Foundation

/// A service responsible for managing authentication state and interacting with Firebase authentication.
@MainActor
class AuthService: ObservableObject {
    // MARK: Private interface

    private let auth: FirebaseAuthProtocol

    // MARK: Internal interface

    /// Indicates whether the user is currently signed in.
    @Published var signedIn: Bool = false
    /// Stores a human-readable authentication error message, if any.
    @Published var authError: String?
    /// Indicates whether the app is currently checking the authentication state.
    @Published var checkingAuthState = true

    /// Initializes the service with a given authentication backend.
    /// - Parameter auth: A FirebaseAuthProtocol-compatible backend (e.g., FirebaseAuthAdapter or a mock).
    init(auth: FirebaseAuthProtocol) {
        self.auth = auth

        /// Observes authentication state changes.
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            signedIn = user != nil
            checkingAuthState = false
        }
    }

    /// Attempts to create a new user account.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    ///   - completion: A closure called with an error if the operation fails.
    func createAnAccount(email: String, password: String, completion: @escaping (Error?) -> Void) {
        authError = nil
        auth.createAnAccount(email: email, password: password) { [weak self] _, error in
            guard let self else { return }
            if let error {
                authError = error.localizedDescription
                completion(error)
            } else {
                signedIn = true
                completion(nil)
            }
        }
    }

    /// Attempts to sign in an exicting user.
    /// - Parameters:
    ///   - email: The user's email.
    ///   - password: The user's password.
    ///   - completion: A closure called with an error if the operation fails.
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        authError = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard let self else { return }

            if error == nil {
                signedIn = true
            }
            completion(error)
        }
    }
}
