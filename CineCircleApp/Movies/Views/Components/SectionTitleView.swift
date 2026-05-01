import SwiftUI

struct SectionTitleView: View {
    let title: String
    let destination: AnyView?

    init(title: String, destination: some View) {
        self.title = title
        self.destination = AnyView(destination)
    }

    init(title: String) {
        self.title = title
        destination = nil
    }

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()

            if let destination {
                NavigationLink(Parameters.seeAllText) {
                    destination
                }
                .foregroundColor(.gray)
            }
        }
        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.sectionHeaderFontSize))
        .padding(.bottom, Parameters.sectionHeaderSpacing)
    }

    // MARK: Private interface

    private enum Parameters {
        static let sectionHeaderFontSize: CGFloat = 16
        static let seeAllText = "See all"
        static let sectionHeaderSpacing: CGFloat = 24
    }
}

#Preview {
    SectionTitleView(title: "Gallery")
}
