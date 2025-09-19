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
        .padding(.bottom, sectionHeaderSpacing)
    }

    // MARK: Private interface

    private let poppinsFont = "Poppins"
    private let sectionHeaderFontSize: CGFloat = 16
    private let seeAllText = "See all"
    private let sectionHeaderSpacing: CGFloat = 24
}

#Preview {
    SectionHeader(title: "Gallery")
}
