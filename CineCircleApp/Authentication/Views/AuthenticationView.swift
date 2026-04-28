import SwiftUI

struct AuthenticationView: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    isSigningUp.toggle()
                    viewModel.email = ""
                    viewModel.password = ""
                } label: {
                    signUpButton
                }
            }
            .padding(.horizontal, Parameters.horizontalPadding)
            .padding(.top, Parameters.topPadding)

            Spacer()

            VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
                Text(isSigningUp ? signUpWelcomeText : logInWilcomeText)
                    .font(Font.custom(AppUI.FontName.poppinsBold, size: Parameters.welcomeTextFontSize))
                    .foregroundStyle(Color.black)
                    .frame(width: Parameters.welcomeTextWidth, alignment: .topLeading)

                if isSigningUp {
                    Text(signUpDescription)
                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.descriptionFontSize))
                        .foregroundStyle(Color.black)
                        .frame(width: Parameters.welcomeTextWidth, alignment: .topLeading)
                }

                AuthenticationFieldsView(
                    email: $viewModel.email,
                    password: $viewModel.password
                )

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.alertFontSize))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    authenticate()
                } label: {
                    logInButton
                }
                .padding(.vertical, Parameters.buttonVerticalPadding)
                .frame(width: Parameters.loginButtonWidth, alignment: .center)
                .background(AppUI.ColorPalette.accent)
                .cornerRadius(AppUI.Radius.card)

                Divider()
            }
            .padding(.horizontal, Parameters.horizontalPadding)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
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

    private var logInButton: some View {
        Text(isSigningUp ? "Sign up" : "Log in")
            .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.loginButtonFontSize))
            .foregroundColor(Color.black)
    }

    private var signUpButton: some View {
        Text(isSigningUp ? "Log in" : "Sign Up")
            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.switchModeFontSize))
            .foregroundColor(Color.black)
    }

    private let signUpWelcomeText = "Hello there 👋"
    private let signUpDescription = "Sign up and dive into a world of cinema."
    private let logInWilcomeText = "Welcome back\nto CineCircle!"

    private enum Parameters {
        static let welcomeTextFontSize: CGFloat = 36
        static let descriptionFontSize: CGFloat = 14
        static let switchModeFontSize: CGFloat = 16
        static let alertFontSize: CGFloat = 14
        static let welcomeTextWidth: CGFloat = 280
        static let loginButtonFontSize: CGFloat = 16
        static let loginButtonWidth: CGFloat = 370
        static let contentSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 8
        static let buttonVerticalPadding: CGFloat = 16
    }
}

#Preview {
    AuthenticationView()
}
