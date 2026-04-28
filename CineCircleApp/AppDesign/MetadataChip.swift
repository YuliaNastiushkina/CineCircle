import SwiftUI

struct MetadataChip: View {
    let text: String
    let font: Font
    let textColor: Color
    let backgroundColor: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    init(
        text: String,
        font: Font = Font.custom(AppUI.FontName.poppins, size: 13),
        textColor: Color = AppUI.ColorPalette.chipText,
        backgroundColor: Color = AppUI.ColorPalette.secondarySurface,
        horizontalPadding: CGFloat = 12,
        verticalPadding: CGFloat = 7
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(textColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

#Preview {
    MetadataChip(text: "1h 42m")
}
