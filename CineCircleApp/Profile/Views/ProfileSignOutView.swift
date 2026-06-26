import SwiftUI

struct ProfileSignOutView: View {
    let signOutAction: () -> Void
    let deleteAccountAction: (() -> Void)?
    let isDeletingAccount: Bool

    init(
        signOutAction: @escaping () -> Void,
        deleteAccountAction: (() -> Void)? = nil,
        isDeletingAccount: Bool = false
    ) {
        self.signOutAction = signOutAction
        self.deleteAccountAction = deleteAccountAction
        self.isDeletingAccount = isDeletingAccount
    }

    var body: some View {
        VStack(spacing: Parameters.spacing) {
            Button(role: .destructive, action: signOutAction) {
                Text(Parameters.signOutLabel)
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.fontSize))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if let deleteAccountAction {
                Button(role: .destructive, action: deleteAccountAction) {
                    HStack {
                        if isDeletingAccount {
                            ProgressView()
                        }

                        Text(Parameters.deleteAccountLabel)
                            .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.fontSize))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isDeletingAccount)
            }
        }
        .padding(.top, Parameters.topPadding)
    }

    private enum Parameters {
        static let signOutLabel = "Sign Out"
        static let deleteAccountLabel = "Delete Account"
        static let fontSize: CGFloat = 16
        static let spacing: CGFloat = 12
        static let topPadding: CGFloat = 24
    }
}

#Preview {
    ProfileSignOutView(signOutAction: {}, deleteAccountAction: {})
        .padding()
}
