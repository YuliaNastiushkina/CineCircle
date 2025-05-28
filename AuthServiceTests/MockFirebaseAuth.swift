@testable import CineCircle
import FirebaseAuth

/// A mock implementation of `FirebaseAuthProtocol` used for unit testing.
class MockFirebaseAuth: FirebaseAuthProtocol {
    var shouldReturnError = false
    var lastEmail: String?
    var lastPassword: String?
    var signedInUser: User?

    func createAnAccount(email: String, password: String, completion: @escaping (FirebaseAuth.AuthDataResult?, (any Error)?) -> Void) {
        lastEmail = email
        lastPassword = password
        if shouldReturnError {
            completion(nil, NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock createUser error"]))
        } else {
            completion(nil, nil)
        }
    }

    func signIn(email _: String, password _: String, completion _: @escaping (FirebaseAuth.AuthDataResult?, (any Error)?) -> Void) {}

    func signOut() throws {}

    func addStateDidChangeListener(_: @escaping (FirebaseAuth.Auth, FirebaseAuth.User?) -> Void) {}
}
