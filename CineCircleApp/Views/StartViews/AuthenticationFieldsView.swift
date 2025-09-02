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
                .padding(fieldPadding)
                .font(Font.custom(poppinsFont, size: labelSize))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: fieldCornerRadius)
                        .stroke(showEmailError ? Color.red : Color.gray, lineWidth: 1)
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
                    .font(Font.custom(poppinsFont, size: alertSize))
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
                .padding(fieldPadding)
                .font(Font.custom(poppinsFont, size: labelSize))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: fieldCornerRadius)
                        .stroke(showPasswordError ? Color.red : Color.gray, lineWidth: lineWidth)
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
                        .padding(.trailing, 12)
                }
            }
            .padding(.top)

            if showPasswordError {
                Text(passwordAlert)
                    .foregroundColor(.red)
                    .font(Font.custom(poppinsFont, size: alertSize))
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
    private let poppinsFont = "Poppins"
    private let labelSize: CGFloat = 14
    private let fieldPadding: CGFloat = 16
    private let emailAlert = "Invalid email address"
    private let passwordAlert = "Password must be at least 6 characters"
    private let alertSize: CGFloat = 10
    private let lineWidth: CGFloat = 1
    private let fieldCornerRadius: CGFloat = 24
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
