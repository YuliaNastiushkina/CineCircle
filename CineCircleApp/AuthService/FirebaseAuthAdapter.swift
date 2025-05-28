import FirebaseAuth

/// A concrete implementation of `FirebaseAuthProtocol` that uses Firebase's real authentication API.
class FirebaseAuthAdapter: FirebaseAuthProtocol {
    func createAnAccount(email _: String, password _: String, completion _: @escaping (FirebaseAuth.AuthDataResult?, (any Error)?) -> Void) {}

    func signIn(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password, completion: completion)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func addStateDidChangeListener(_ listener: @escaping (Auth, User?) -> Void) {
        Auth.auth().addStateDidChangeListener(listener)
    }
}
