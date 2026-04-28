import SwiftUI

enum AppUI {
    enum ColorPalette {
        static let accent = Color(red: 1, green: 0.83, blue: 0.24)
        static let placeholderBackground = Color(.systemGray5)
        static let secondarySurface = Color(.systemGray6)
        static let softCardBackground = Color.secondary.opacity(0.15)
        static let chipText = Color(.darkGray)
    }

    enum FontName {
        static let poppins = "Poppins"
        static let poppinsBold = "Poppins-Bold"
        static let poppinsLight = "Poppins-Light"
        static let poppinsSemiBold = "Poppins-SemiBold"
    }

    enum Radius {
        static let card: CGFloat = 24
        static let medium: CGFloat = 14
    }
}
