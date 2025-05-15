import SwiftUI

struct LogoView: View {
    var body: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(height: 25)
            .opacity(0.6)
    }
}

#Preview {
    LogoView()
}
