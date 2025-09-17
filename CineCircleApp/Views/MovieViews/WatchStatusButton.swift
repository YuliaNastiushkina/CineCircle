import SwiftUI

struct WatchStatusButton: View {
    @Environment(\.managedObjectContext) private var context

    let movieID: Int
    let userID: String

    var body: some View {
        Button(action: toggleWatched) {
            HStack {
                Image(systemName: "eye")
                Text("Unseen")
            }
            .foregroundStyle(isSeen ? .yellow : .secondary)
        }
        .onAppear(perform: loadWatchedStatus)
    }

    // MARK: Private interface

    @State private var isWatched: Bool = false

    private func loadWatchedStatus() {
        let service = WatchedMovieService(context: context)
        isWatched = service.isWatched(movieId: movieID, userId: userID)
    }

    private func toggleWatched() {
        let service = WatchedMovieService(context: context)
        service.toggleWatched(movieId: movieID, userId: userID)

        withAnimation {
            isWatched = service.isWatched(movieId: movieID, userId: userID)
        }
    }
}

#Preview {
    WatchStatusButton(movieID: 1, userID: "1")
}
