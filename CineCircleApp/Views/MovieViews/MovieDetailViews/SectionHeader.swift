import SwiftUI

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Button(seeAllText) {}
                .foregroundColor(.gray)
        }
        .font(Font.custom(poppinsFont, size: sectionHeaderFontSize))
    }

    // MARK: Private interface

    private let poppinsFont = "Poppins"
    private let sectionHeaderFontSize: CGFloat = 16
    private let seeAllText = "See all"
}

#Preview {
    SectionHeader(title: "Gallery")
}
