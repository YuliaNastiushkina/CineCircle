import FirebaseAuth
import Foundation
import SwiftUI

/// Manages the login screen logic, including user input validation, sign-in flow, and UI state updates.
@MainActor
class LoginViewModel: ObservableObject {
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
    /// Validates the email and password, shows an error message if invalid, and calls the
    /// sign-in method on the `authService`. If authentication fails, an error message is shown.
    ///
    /// - Parameter authService: An object conforming to `AuthService` used to perform the sign-in.
    func signIn(authService: AuthService) {
        guard isEmailValid, isPasswordValid else {
            errorMessage = "Please enter a valid email and password."
            return
        }

        isLoggingIn = true

        authService.signIn(email: email, password: password) { [weak self] _ in
            guard let self else { return }
            errorMessage = "Incorrect email or password.\nPlease try again."
            isLoggingIn = false
        }
    }
}
