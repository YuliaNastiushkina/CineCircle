import SwiftUI

struct BookmarkButton: View {
    @Environment(\.managedObjectContext) private var context

    let movieID: Int
    let userID: String

    @State private var isSaved = false

    var body: some View {
        CircleButton(systemName: isSaved ? "bookmark.fill" : "bookmark", action: toggleSaved)
            .foregroundStyle(isSaved ? AppUI.ColorPalette.accent : Color.white)
            .onAppear(perform: loadSaved)
    }

    // MARK: - Private interface

    private func loadSaved() {
        let service = SavedMovieService(context: context)
        isSaved = service.isSaved(movieId: movieID, userId: userID)
    }

    private func toggleSaved() {
        let service = SavedMovieService(context: context)
        service.toggleSaved(movieId: movieID, userId: userID)
        withAnimation(.spring(response: Parameters.springResponse, dampingFraction: Parameters.springDampingFraction)) {
            isSaved = service.isSaved(movieId: movieID, userId: userID)
        }
    }

    private enum Parameters {
        static let springResponse = 0.25
        static let springDampingFraction = 0.8
    }
}

#Preview {
    BookmarkButton(movieID: 1, userID: "previewUser")
}
