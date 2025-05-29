import Foundation
import SwiftUI

@MainActor
class RegistrationViewModel: ObservableObject {
    /// The user's email input.
    @Published var email = ""
    /// The user's password input.
    @Published var password = ""
    /// An error message displayed in the UI when login fails or input is invalid.
    @Published var errorMessage = ""

    /// Checks if the current email input is valid.
    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    /// Checks if the current password input is valid (at least 6 characters).
    var isPasswordValid: Bool {
        password.count >= 6
    }

    /// Attempts to create a new account using the provided authentication service.
    /// - Parameter authService: The service responsible for handling authentication requests.
    func createAnAccount(authService: AuthService) {
        guard isEmailValid, isPasswordValid else {
            errorMessage = "Please enter a valid email and password."
            return
        }

        authService.createAnAccount(email: email, password: password) { [weak self] error in
            print("callback called on thread:", Thread.isMainThread ? "main" : "background")
            guard let self else { return }
            if let error {
                errorMessage = error.localizedDescription
                print("Error")
            } else {
                errorMessage = ""
            }
            print("account created")
        }
    }
}
