import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack {
            AuthenticationFieldsView(email: $viewModel.email, password: $viewModel.password)

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Sign in") {
                viewModel.signIn(authService: authService)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            VStack {
                Text("Do not have an account? ")

                NavigationLink(destination: RegistrationView()) {
                    Text("Create an account").foregroundColor(.blue)
                }
            }.frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
