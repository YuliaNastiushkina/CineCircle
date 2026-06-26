import SwiftUI

struct AuthenticationView: View {
    @Environment(\.authService) private var authService: AuthServiceProtocol
    @EnvironmentObject private var userSession: UserSession

    var body: some View {
        AuthenticationContentView(authService: authService, userSession: userSession)
    }
}

private struct AuthenticationContentView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @State private var isSigningUp = false
    @State private var showVerificationSentAlert = false
    private let userSession: UserSession

    init(authService: AuthServiceProtocol, userSession: UserSession) {
        self.userSession = userSession
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }

    var body: some View {
        VStack {
            modeSwitchHeader

            Spacer()

            VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
                Text(isSigningUp ? signUpWelcomeText : logInWelcomeText)
                    .font(Font.custom(AppUI.FontName.poppinsBold, size: Parameters.welcomeTextFontSize))
                    .foregroundStyle(Color.black)
                    .frame(width: Parameters.welcomeTextWidth, alignment: .topLeading)

                if isSigningUp {
                    Text(signUpDescription)
                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.descriptionFontSize))
                        .foregroundStyle(Color.black)
                        .frame(width: Parameters.welcomeTextWidth, alignment: .topLeading)
                }

                if isSigningUp {
                    TextField("Nickname", text: $viewModel.nickname)
                        .textContentType(.nickname)
                        .padding(Parameters.fieldPadding)
                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.fieldFontSize))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppUI.Radius.card)
                                .stroke(Color.gray, lineWidth: Parameters.borderWidth)
                        )
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                AuthenticationFieldsView(
                    email: $viewModel.email,
                    password: $viewModel.password,
                    isSigningUp: isSigningUp
                )

                messageView

                Button {
                    authenticate()
                } label: {
                    primaryButtonLabel
                }
                .padding(.vertical, Parameters.buttonVerticalPadding)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(viewModel.isProcessing ? Color.gray.opacity(0.5) : AppUI.ColorPalette.accent)
                .cornerRadius(AppUI.Radius.card)
                .disabled(viewModel.isProcessing)

                if !isSigningUp {
                    Button {
                        sendPasswordReset()
                    } label: {
                        Text("Forgot password?")
                            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.forgotPasswordFontSize))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.isProcessing)
                }

                Divider()
            }
            .padding(.horizontal, Parameters.horizontalPadding)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .alert(verificationAlertTitle, isPresented: $showVerificationSentAlert) {
            Button("Continue") {
                userSession.finishSignupPresentationDelay()
            }
        } message: {
            Text(verificationAlertMessage)
        }
    }

    private var modeSwitchHeader: some View {
        HStack {
            Spacer()
            Button {
                isSigningUp.toggle()
                viewModel.nickname = ""
                viewModel.email = ""
                viewModel.password = ""
                viewModel.clearMessages()
            } label: {
                Text(isSigningUp ? "Log in" : "Sign Up")
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.switchModeFontSize))
                    .foregroundColor(Color.black)
            }
            .disabled(viewModel.isProcessing)
        }
        .padding(.horizontal, Parameters.horizontalPadding)
        .padding(.top, Parameters.topPadding)
    }

    @ViewBuilder
    private var messageView: some View {
        if !viewModel.errorMessage.isEmpty {
            Text(viewModel.errorMessage)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.alertFontSize))
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if !viewModel.infoMessage.isEmpty {
            Text(viewModel.infoMessage)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.alertFontSize))
                .foregroundColor(.green)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var verificationAlertTitle: String {
        viewModel.didSendVerificationEmail ? "Verification Email Sent" : "Account Created"
    }

    private var verificationAlertMessage: String {
        if viewModel.didSendVerificationEmail {
            return "Check your inbox when you have a moment. Verifying your email helps keep password reset and future account recovery secure."
        }
        return "We could not send the verification email right now. You can continue using the app and try again later from your profile."
    }

    private var primaryButtonLabel: some View {
        HStack(spacing: Parameters.progressSpacing) {
            if viewModel.isProcessing {
                ProgressView()
                    .tint(.black)
            }

            Text(isSigningUp ? "Sign up" : "Log in")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.loginButtonFontSize))
                .foregroundColor(Color.black)
        }
    }

    private func authenticate() {
        Task {
            if isSigningUp {
                userSession.beginSignupPresentationDelay()
                let didCreateAccount = await viewModel.createAnAccount()
                if didCreateAccount {
                    showVerificationSentAlert = true
                } else {
                    userSession.cancelSignupPresentationDelay()
                }
            } else {
                await viewModel.signIn()
            }
        }
    }

    private func sendPasswordReset() {
        Task {
            await viewModel.sendPasswordReset()
        }
    }

    private let signUpWelcomeText = "Hello there"
    private let signUpDescription = "Sign up and dive into a world of cinema."
    private let logInWelcomeText = "Welcome back\nto CineCircle!"

    private enum Parameters {
        static let welcomeTextFontSize: CGFloat = 36
        static let descriptionFontSize: CGFloat = 14
        static let switchModeFontSize: CGFloat = 16
        static let alertFontSize: CGFloat = 14
        static let welcomeTextWidth: CGFloat = 280
        static let loginButtonFontSize: CGFloat = 16
        static let forgotPasswordFontSize: CGFloat = 14
        static let fieldFontSize: CGFloat = 14
        static let fieldPadding: CGFloat = 16
        static let borderWidth: CGFloat = 1
        static let contentSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 8
        static let buttonVerticalPadding: CGFloat = 16
        static let progressSpacing: CGFloat = 8
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(UserSession())
}
