import SwiftUI

struct MainView: View {
    @Environment(\.authService) private var authService: AuthServiceProtocol
    @EnvironmentObject private var userSession: UserSession

    var body: some View {
        switch userSession.authState {
        case .undefined:
            ProgressView("Checking auth...")
        case .notAuthenticated:
            AuthenticationView()
        case let .authenticated(userId):
            MainTabView(userId: userId)
        }
    }
}

#Preview {
    MainView()
}
