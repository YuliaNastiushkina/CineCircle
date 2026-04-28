import FirebaseAuth
import Foundation

/// An abstraction over authentication services. Provides basic account management functions.
protocol AuthServiceProtocol {
    func createAnAccount(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() throws
}
