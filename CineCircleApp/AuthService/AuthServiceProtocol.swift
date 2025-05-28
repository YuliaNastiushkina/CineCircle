import Foundation
import FirebaseAuth

/// Abstracts Firebase authentication methods for dependency injection and testing.
protocol FirebaseAuthProtocol {
    func createAnAccount(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void)
    func signIn(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void)
    func signOut() throws
    func addStateDidChangeListener(_ listener: @escaping (Auth, User?) -> Void)
}
