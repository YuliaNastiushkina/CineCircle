import SwiftUI

struct AuthenticationFieldsView: View {
    @Binding var email: String
    @Binding var password: String

    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    var isPasswordValid: Bool {
        password.count >= 6
    }

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isEmailValid || email.isEmpty ? Color.gray : Color.red, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if !isEmailValid && !email.isEmpty {
                Text("Invalid email address")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            SecureField("Password", text: $password)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isPasswordValid || password.isEmpty ? Color.gray : Color.red, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if !isPasswordValid && !password.isEmpty {
                Text("Password must be at least 6 characters.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding()
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
