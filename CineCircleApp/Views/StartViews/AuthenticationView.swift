import SwiftUI

struct AuthenticationView: View {
    var body: some View {
        VStack {
            AuthenticationFieldsView(email: $viewModel.email, password: $viewModel.password)

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("\(isSigningUp ? "Sign up" : "Sign in")") {
                authenticate()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("\(isSigningUp ? "I already have an account" : "I don't have an account")") {
                isSigningUp.toggle()
            }
            .padding(.top)
        }
        .padding()
    }

    // MARK: Private interface

    @StateObject private var viewModel = AuthenticationViewModel(authService: FirebaseAuthService())
    @State private var isSigningUp: Bool = false

    private func signIn() {
        Task {
            await viewModel.signIn()
        }
    }

    private func signUp() {
        Task {
            await viewModel.createAnAccount()
        }
    }

    private func authenticate() {
        isSigningUp ? signUp() : signIn()
    }
}

#Preview {
    AuthenticationView()
}
