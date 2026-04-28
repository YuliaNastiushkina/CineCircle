import FirebaseAuth
import Foundation
import SwiftUI

/// Manages the login and registration logic, including user input validation, authentication flow, and UI state updates.
@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: Private interface

    private let authService: AuthServiceProtocol

    // MARK: Internal interface

    /// Initializes the view model with a dependency-injected authentication service.
    /// - Parameter authService: The authentication service used to perform sign-in and account creation.
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    /// The user's email input.
    @Published var email = ""
    /// The user's password input.
    @Published var password = ""
    /// An error message displayed in the UI when login fails or input is invalid.
    @Published var errorMessage = ""
    /// Indicates whether a login request is currently in progress.
    @Published var isLoggingIn = false

    /// Checks if the current email input is valid.
    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    /// Checks if the current password input is valid (at least 6 characters).
    var isPasswordValid: Bool {
        password.count >= 6
    }

    /// Attempts to sign in the user using the provided authentication service.
    /// If authentication fails, sets an appropriate `errorMessage`.
    func signIn() async {
        guard isEmailValid, isPasswordValid else {
            errorMessage = "Please enter a valid email and password."
            return
        }

        isLoggingIn = true
        defer { isLoggingIn = false }

        do {
            try await authService.signIn(email: email, password: password)
            errorMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Attempts to create a new user account using the provided authentication service.
    /// If the operation fails, sets an appropriate `errorMessage`.
    func createAnAccount() async {
        guard isEmailValid, isPasswordValid else {
            errorMessage = "Please enter a valid email and password."
            return
        }

        do {
            try await authService.createAnAccount(email: email, password: password)
            errorMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
