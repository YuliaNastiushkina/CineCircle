import SwiftUI

struct CircleButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(white: Constants.overlayCircleColor, opacity: Constants.overlayCircleOpacity))
                .frame(width: Constants.overlayCircleSize, height: Constants.overlayCircleSize)
                .overlay(
                    Image(systemName: systemName)
                        .renderingMode(.template)
                        .fontWeight(.bold)
                        .font(.system(size: Constants.buttonIconFontSize))
                )
        }
    }

    // MARK: - Constants

    private enum Constants {
        static let overlayCircleSize: CGFloat = 45
        static let overlayCircleOpacity: Double = 0.8
        static let overlayCircleColor: Double = 0.32
        static let buttonIconFontSize: CGFloat = 20
    }
}

#Preview {
    CircleButton(systemName: "xmark") {
        print("Button tapped")
    }
}
