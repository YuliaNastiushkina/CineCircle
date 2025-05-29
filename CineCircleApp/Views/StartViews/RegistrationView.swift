import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = RegistrationViewModel()

    var body: some View {
        VStack {
            VStack {
                AuthenticationFieldsView(email: $viewModel.email, password: $viewModel.password)

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                }

                Button("Create an account") {
                    print("tapped")
                    viewModel.createAnAccount(authService: authService)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack {
                Text("Already have an account? ")

                NavigationLink(destination: LoginView()) {
                    Text("Login").foregroundColor(.blue)
                }
            }.frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthService(auth: FirebaseAuthAdapter()))
}
