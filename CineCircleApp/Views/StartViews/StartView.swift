// import SwiftUI
//
// struct StartView: View {
//    @Environment(\.authService) private var authService: AuthServiceProtocol
//
//    var body: some View {
//        if authService.checkingAuthState {
//            ProgressView()
//        } else if authService.signedIn {
//            MainView()
//        } else {
//            NavigationStack {
//                LoginView()
//            }
//        }
//    }
// }
//
// #Preview {
//    StartView()
// }
