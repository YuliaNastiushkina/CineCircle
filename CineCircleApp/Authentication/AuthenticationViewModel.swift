import FirebaseAuth
import Foundation
import SwiftUI

/// Manages login and registration logic, including input validation, auth flow, and UI state updates.
@MainActor
class AuthenticationViewModel: ObservableObject {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    @Published var nickname = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var infoMessage = ""
    @Published var didSendVerificationEmail = false
    @Published var isProcessing = false

    var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmailValid: Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return normalizedEmail.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    var isPasswordValid: Bool {
        password.count >= Parameters.minimumPasswordLength
    }

    var isNicknameValid: Bool {
        trimmedNickname.count >= Parameters.minimumNicknameLength
    }

    func signIn() async {
        guard validateCredentials() else { return }
        await runAuthRequest {
            try await authService.signIn(email: normalizedEmail, password: password)
            clearMessages()
        }
    }

    @discardableResult func createAnAccount() async -> Bool {
        guard validateSignupInput() else { return false }
        return await runAuthRequest {
            try await authService.createAnAccount(email: normalizedEmail, password: password)
            storeNicknameForCurrentUser()
            didSendVerificationEmail = await sendVerificationEmailIfPossible()
            password = ""
            errorMessage = ""
            infoMessage = didSendVerificationEmail
                ? "Account created. Check your email when you have a moment to verify your address."
                : "Account created, but we could not send the verification email. You can continue using the app and try again later."
        }
    }

    func sendPasswordReset() async {
        guard isEmailValid else {
            errorMessage = "Enter a valid email address to reset your password."
            infoMessage = ""
            return
        }

        await runAuthRequest {
            try await authService.sendPasswordReset(email: normalizedEmail)
            errorMessage = ""
            infoMessage = "Password reset email sent. Check your inbox for the next step."
        }
    }

    func clearMessages() {
        errorMessage = ""
        infoMessage = ""
    }

    private func validateSignupInput() -> Bool {
        guard isNicknameValid else {
            errorMessage = "Enter a nickname with at least \(Parameters.minimumNicknameLength) characters."
            infoMessage = ""
            return false
        }

        return validateCredentials()
    }

    private func validateCredentials() -> Bool {
        guard isEmailValid else {
            errorMessage = "Enter a valid email address."
            infoMessage = ""
            return false
        }

        guard isPasswordValid else {
            errorMessage = "Password must be at least \(Parameters.minimumPasswordLength) characters."
            infoMessage = ""
            return false
        }

        return true
    }

    @discardableResult private func runAuthRequest(_ action: () async throws -> Void) async -> Bool {
        guard !isProcessing else { return false }
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await action()
            return true
        } catch {
            errorMessage = friendlyMessage(for: error)
            infoMessage = ""
            return false
        }
    }

    private func storeNicknameForCurrentUser() {
        guard let userId = authService.currentUser?.uid else { return }
        UserDefaults.standard.set(trimmedNickname, forKey: ProfileUserDefaultsKeys.name(for: userId))
    }

    private func sendVerificationEmailIfPossible() async -> Bool {
        do {
            try await authService.sendEmailVerification()
            return true
        } catch {
            return false
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if let authError = error as? AuthServiceError {
            switch authError {
            case .noCurrentUser:
                return "We could not find an active account session. Please sign in again."
            case .missingEmail:
                return "This account does not have an email address available."
            case .requiresRecentLogin:
                return "Please sign in again before making this account change."
            }
        }

        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Enter a valid email address."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account already exists for this email. Try logging in instead."
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.userNotFound.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            return "The email or password is incorrect."
        case AuthErrorCode.weakPassword.rawValue:
            return "Choose a stronger password before creating your account."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection and try again."
        case AuthErrorCode.userDisabled.rawValue:
            return "This account is disabled. Contact support if you think this is a mistake."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please wait a moment and try again."
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return "Please sign in again before making this account change."
        default:
            return "Something went wrong. Please try again."
        }
    }

    private enum Parameters {
        static let minimumNicknameLength = 2
        static let minimumPasswordLength = 8
    }
}
