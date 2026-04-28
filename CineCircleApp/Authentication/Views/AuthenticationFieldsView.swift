import SwiftUI

struct AuthenticationFieldsView: View {
    @Binding var email: String
    @Binding var password: String

    @FocusState private var focusedField: Field?
    @State private var emailTouched = false
    @State private var passwordTouched = false
    @State private var showPassword = false

    enum Field {
        case email
        case password
        case confirmPassword
    }

    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    var isPasswordValid: Bool {
        password.count >= 6
    }

    var body: some View {
        VStack {
            TextField(emailPlaceholder, text: $email)
                .padding(Parameters.fieldPadding)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.fieldFontSize))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: AppUI.Radius.card)
                        .stroke(showEmailError ? Color.red : Color.gray, lineWidth: Parameters.borderWidth)
                )
                .focused($focusedField, equals: .email)
                .onChange(of: focusedField) { oldFocus, newFocus in
                    if oldFocus == .email && newFocus != .email {
                        emailTouched = true
                    }
                }

            if showEmailError {
                Text(emailAlert)
                    .foregroundColor(.red)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.alertFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ZStack(alignment: .trailing) {
                Group {
                    if showPassword {
                        TextField(passwordPlaceholder, text: $password)
                    } else {
                        SecureField(passwordPlaceholder, text: $password)
                    }
                }
                .padding(Parameters.fieldPadding)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.fieldFontSize))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: AppUI.Radius.card)
                        .stroke(showPasswordError ? Color.red : Color.gray, lineWidth: Parameters.borderWidth)
                )
                .focused($focusedField, equals: .password)
                .onChange(of: focusedField) { oldFocus, newFocus in
                    if oldFocus == .password && newFocus != .password {
                        passwordTouched = true
                    }
                }

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, Parameters.trailingIconPadding)
                }
            }
            .padding(.top, Parameters.passwordFieldTopPadding)

            if showPasswordError {
                Text(passwordAlert)
                    .foregroundColor(.red)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.alertFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }

    private var showEmailError: Bool {
        emailTouched && !isEmailValid && !email.isEmpty
    }

    private var showPasswordError: Bool {
        passwordTouched && !isPasswordValid && !password.isEmpty
    }

    private let emailPlaceholder = "Email"
    private let passwordPlaceholder = "Password"
    private let emailAlert = "Invalid email address"
    private let passwordAlert = "Password must be at least 6 characters"

    private enum Parameters {
        static let fieldFontSize: CGFloat = 14
        static let fieldPadding: CGFloat = 16
        static let alertFontSize: CGFloat = 10
        static let borderWidth: CGFloat = 1
        static let trailingIconPadding: CGFloat = 12
        static let passwordFieldTopPadding: CGFloat = 8
    }
}

struct SimpleLoginPreview: View {
    @State private var email = "test@example.com"
    @State private var password = "123456"

    var body: some View {
        AuthenticationFieldsView(email: $email, password: $password)
    }
}

#Preview {
    SimpleLoginPreview()
}
