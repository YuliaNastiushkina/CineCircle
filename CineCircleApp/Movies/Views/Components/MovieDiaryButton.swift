import SwiftUI

struct MovieDiaryButton: View {
    let movieId: Int
    let userId: String
    let movieTitle: String

    var body: some View {
        Button {
            isPresentingDiary = true
        } label: {
            HStack {
                Text(buttonTitle)
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
        .sheet(isPresented: $isPresentingDiary, onDismiss: loadDiaryState) {
            MovieDiaryView(movieId: movieId, userId: userId, movieTitle: movieTitle)
        }
        .onAppear(perform: loadDiaryState)
        .onReceive(NotificationCenter.default.publisher(for: .userLibraryDidChange)) { _ in
            loadDiaryState()
        }
    }

    // MARK: - Private interface

    @State private var isPresentingDiary = false
    @State private var hasDiaryEntry = false

    private var buttonTitle: String {
        hasDiaryEntry ? "Revisit this watch" : "Capture this watch"
    }

    private func loadDiaryState() {
        hasDiaryEntry = !NoteService.shared.fetchNotes(for: movieId, userId: userId).isEmpty
    }

    private enum Parameters {
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
    MovieDiaryButton(movieId: 1, userId: "previewUser", movieTitle: "Preview Movie")
}
