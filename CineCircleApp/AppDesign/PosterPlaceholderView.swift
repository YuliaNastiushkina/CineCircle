import SwiftUI

struct PosterPlaceholderView: View {
    let cornerRadius: CGFloat
    let iconSize: CGFloat

    init(
        cornerRadius: CGFloat = AppUI.Radius.medium,
        iconSize: CGFloat = 24
    ) {
        self.cornerRadius = cornerRadius
        self.iconSize = iconSize
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppUI.ColorPalette.placeholderBackground)
            .overlay(
                Image(systemName: "film")
                    .foregroundColor(.gray)
                    .font(.system(size: iconSize))
            )
    }
}

#Preview {
    PosterPlaceholderView()
        .frame(width: 96, height: 144)
}
