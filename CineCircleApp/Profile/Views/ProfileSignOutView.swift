import SwiftUI

struct ProfileSignOutView: View {
    let signOutAction: () -> Void

    var body: some View {
        Button(role: .destructive, action: signOutAction) {
            Text(Parameters.label)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.fontSize))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(.top, Parameters.topPadding)
    }

    private enum Parameters {
        static let label = "Sign Out"
        static let fontSize: CGFloat = 16
        static let topPadding: CGFloat = 24
    }
}

#Preview {
    ProfileSignOutView(signOutAction: {})
        .padding()
}
