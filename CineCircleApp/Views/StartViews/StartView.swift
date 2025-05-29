import SwiftUI

struct StartView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        if authService.checkingAuthState {
            ProgressView()
        } else if authService.signedIn {
            MainView()
        } else {
            NavigationStack {
                LoginView()
            }
        }
    }
}

#Preview {
    StartView()
}
