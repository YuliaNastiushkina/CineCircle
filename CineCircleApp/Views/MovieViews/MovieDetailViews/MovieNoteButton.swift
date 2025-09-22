import SwiftUI

struct MovieNoteButton: View {
    let movieId: Int
    let userId: String

    var body: some View {
        Button {
            isPresentingNote = true
        } label: {
            HStack {
                Text(buttonTitle)
                Image(buttonImageName)
                    .renderingMode(.template)
            }
            .font(Font.custom(poppinsFont, size: fontSize))
            .foregroundColor(.black)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(width: buttonWidth, alignment: .center)
            .background(Color.yellow)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowYOffset)
        }
        .sheet(isPresented: $isPresentingNote) {
            MovieNoteView(movieId: movieId, userId: userId)
        }
    }

    // MARK: - Private interface

    @State private var isPresentingNote = false
    private let buttonTitle = "Write a note"
    private let buttonImageName = "notebookImage"
    private let poppinsFont = "Poppins"
    private let fontSize: CGFloat = 16
    private let horizontalPadding: CGFloat = 24
    private let verticalPadding: CGFloat = 16
    private let buttonWidth: CGFloat = 370
    private let cornerRadius: CGFloat = 24
    private let shadowColor = Color.black.opacity(0.08)
    private let shadowRadius: CGFloat = 8
    private let shadowYOffset: CGFloat = 2
}

#Preview {
    MovieNoteButton(movieId: 1, userId: "previewUser")
}
