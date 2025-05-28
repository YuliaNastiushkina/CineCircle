@testable import CineCircle
import FirebaseAuth

/// A mock implementation of `FirebaseAuthProtocol` used for unit testing.
class MockFirebaseAuth: FirebaseAuthProtocol {
    var createdUsers: [String: String] = [:]
    var signedInUserEmail: String?
    var shouldReturnError = false

    var lastEmail: String?
    var lastPassword: String?

    func createAnAccount(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        lastEmail = email
        lastPassword = password

        guard !shouldReturnError else {
            completion(nil, NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Forced error"]))
            return
        }

        if createdUsers[email] != nil {
            completion(nil, NSError(domain: "MockAuth", code: 409, userInfo: [NSLocalizedDescriptionKey: "User already exists"]))
        } else {
            createdUsers[email] = password
            signedInUserEmail = email
            completion(nil, nil)
        }
    }

    func signIn(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        lastEmail = email
        lastPassword = password

        guard !shouldReturnError else {
            completion(nil, NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Forced error"]))
            return
        }

        if let storedPassword = createdUsers[email], storedPassword == password {
            signedInUserEmail = email
            completion(nil, nil)
        } else {
            completion(nil, NSError(domain: "MockAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"]))
        }
    }

    func signOut() throws {}

    func addStateDidChangeListener(_: @escaping (FirebaseAuth.Auth, FirebaseAuth.User?) -> Void) {}
}
