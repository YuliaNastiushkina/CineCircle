import SwiftUI

enum AppUI {
    enum ColorPalette {
        static let accent = Color(red: 1, green: 0.83, blue: 0.24)
        static let placeholderBackground = Color(.systemGray5)
        static let secondarySurface = Color(.systemGray6)
        static let softCardBackground = Color.secondary.opacity(0.15)
        static let chipText = Color(.darkGray)
        static let tabBarBackground = Color.white
        static let tabBarSelectedBackground = Color.black.opacity(0.88)
        static let tabBarInactive = Color(.darkGray)
        static let tabBarShadow = Color.black.opacity(0.08)
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

    enum TMDB {
        static let posterBase = "https://image.tmdb.org/t/p/w342"
        static let stillBase = "https://image.tmdb.org/t/p/w300"
        static let profileBase = "https://image.tmdb.org/t/p/w500"
        static let heroBase = "https://image.tmdb.org/t/p/w780"
    }

    enum PosterSize {
        static let standardWidth: CGFloat = 100
        static let standardHeight: CGFloat = 150
        static let compactWidth: CGFloat = 72
        static let compactHeight: CGFloat = 108
        static let cornerRadius: CGFloat = 12
        static let placeholderIconSize: CGFloat = 20
    }

    enum FontSize {
        static let caption: CGFloat = 12
        static let footnote: CGFloat = 13
        static let body: CGFloat = 14
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }
}
