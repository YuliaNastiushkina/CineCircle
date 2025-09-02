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
            .padding(.horizontal, padding16)
            .padding(.top, topPadding)

            Spacer()

            VStack(alignment: .leading, spacing: spacing) {
                Text(isSigningUp ? signUpWelcomeText : logInWilcomeText)
                    .font(Font.custom(poppinsBoldFont, size: welcomeTextFontSize))
                    .foregroundStyle(Color.black)
                    .frame(width: frameForWelcomeText, alignment: .topLeading)

                if isSigningUp {
                    Text(signUpDescription)
                        .font(Font.custom(poppinsFont, size: smallTextSize))
                        .foregroundStyle(Color.black)
                        .frame(width: frameForWelcomeText, alignment: .topLeading)
                }

                AuthenticationFieldsView(
                    email: $viewModel.email,
                    password: $viewModel.password
                )

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(Font.custom(poppinsFont, size: authenticationAlertSize))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    authenticate()
                } label: {
                    logInButton
                }
                .padding(.vertical, padding16)
                .frame(width: frameForLogInButton, alignment: .center)
                .background(buttonColor)
                .cornerRadius(buttonCornerRadius)

                Divider()
            }
            .padding(.horizontal, padding16)

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
            .font(Font.custom(poppinsSemiBoldFont, size: logInButtonTextSize))
            .foregroundColor(Color.black)
    }

    private var signUpButton: some View {
        Text(isSigningUp ? "Log in" : "Sign Up")
            .font(Font.custom(poppinsFont, size: signUpTextSize))
            .foregroundColor(Color.black)
    }

    private let signUpWelcomeText = "Hello there 👋"
    private let signUpDescription = "Sign up and dive into a world of cinema."
    private let logInWilcomeText = "Welcome back\nto CineCircle!"
    private let poppinsFont = "Poppins"
    private let poppinsBoldFont = "Poppins-Bold"
    private let poppinsSemiBoldFont = "Poppins-SemiBold"
    private let welcomeTextFontSize: CGFloat = 36
    private let smallTextSize: CGFloat = 14
    private let signUpTextSize: CGFloat = 16
    private let authenticationAlertSize: CGFloat = 14
    private let frameForWelcomeText: CGFloat = 280
    private let logInButtonTextSize: CGFloat = 16
    private let frameForLogInButton: CGFloat = 370
    private let buttonColor: Color = .init(red: 1, green: 0.83, blue: 0.24)
    private let buttonCornerRadius: CGFloat = 24
    private let spacing: CGFloat = 24
    private let padding16: CGFloat = 16
    private let topPadding: CGFloat = 8
    private let lineWidth: CGFloat = 1
}

#Preview {
    AuthenticationView()
}
