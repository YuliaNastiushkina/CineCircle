import SwiftUI

struct ProfileSignOutView: View {
    let signOutAction: () -> Void

    var body: some View {
        Button(role: .destructive, action: signOutAction) {
            Text("Sign Out")
                .font(Font.custom("Poppins-SemiBold", size: 16))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(.top, 24)
    }
}

#Preview {
    ProfileSignOutView(signOutAction: {})
        .padding()
}
