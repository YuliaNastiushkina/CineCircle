import SwiftUI

struct MovieNoteButton: View {
    let movieId: Int
    let userId: String

    var body: some View {
        Button {
            isPresentingNote = true
        } label: {
            HStack {
                Text(Parameters.buttonTitle)
                Image(Parameters.buttonImageName)
                    .renderingMode(.template)
            }
            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.fontSize))
            .foregroundColor(.black)
            .padding(.horizontal, Parameters.horizontalPadding)
            .padding(.vertical, Parameters.verticalPadding)
            .frame(width: Parameters.buttonWidth, alignment: .center)
            .background(AppUI.ColorPalette.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
            .shadow(
                color: Color.black.opacity(Parameters.shadowOpacity),
                radius: Parameters.shadowRadius,
                y: Parameters.shadowYOffset
            )
        }
        .sheet(isPresented: $isPresentingNote) {
            MovieNoteView(movieId: movieId, userId: userId)
        }
    }

    // MARK: - Private interface

    @State private var isPresentingNote = false

    private enum Parameters {
        static let buttonTitle = "Write a note"
        static let buttonImageName = "notebookImage"
        static let fontSize: CGFloat = 16
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 16
        static let buttonWidth: CGFloat = 370
        static let shadowOpacity: Double = 0.08
        static let shadowRadius: CGFloat = 8
        static let shadowYOffset: CGFloat = 2
    }
}

#Preview {
    MovieNoteButton(movieId: 1, userId: "previewUser")
}
