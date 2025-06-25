import SwiftUI

extension EnvironmentValues {
    /// Provides access to an `AuthServiceProtocol` from the environment.
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

// MARK: Private interface

private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: AuthServiceProtocol = FirebaseAuthService()
}
