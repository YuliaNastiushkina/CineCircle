import SwiftUI

struct WatchStatusButton: View {
    @Environment(\.managedObjectContext) private var context

    let movieID: Int
    let userID: String
    let movieTitle: String
    let posterPath: String?

    var body: some View {
        Button(action: toggleWatched) {
            HStack {
                Text(isWatched ? Parameters.seenText : Parameters.unseenText)
                Image(systemName: "eye")
            }
            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.textSize))
            .foregroundStyle(isWatched ? AppUI.ColorPalette.accent : .white)
        }
        .onAppear(perform: loadWatchedStatus)
    }

    // MARK: Private interface

    @State private var isWatched: Bool = false

    private enum Parameters {
        static let textSize: CGFloat = 16
        static let seenText = "Watched"
        static let unseenText = "Watch"
    }

    private func loadWatchedStatus() {
        let service = WatchedMovieService(context: context)
        isWatched = service.isWatched(movieId: movieID, userId: userID)
    }

    private func toggleWatched() {
        let service = WatchedMovieService(context: context)
        service.toggleWatched(movieId: movieID, userId: userID, title: movieTitle, posterPath: posterPath)

        withAnimation {
            isWatched = service.isWatched(movieId: movieID, userId: userID)
        }
    }
}

#Preview {
    WatchStatusButton(movieID: 1, userID: "1", movieTitle: "Preview Movie", posterPath: nil)
}
