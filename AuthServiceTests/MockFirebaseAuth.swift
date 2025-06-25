@testable import CineCircle
import FirebaseAuth

/// A mock implementation of `FirebaseAuthProtocol` used for unit testing.
class MockFirebaseAuth: AuthServiceProtocol {
    var createdUsers: [String: String] = [:]
    var signedInUserEmail: String?
    var shouldReturnError = false

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
        } else {
            throw NSError(domain: "MockAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
    }

    func signOut() throws {
        signedInUserEmail = nil
    }
}
