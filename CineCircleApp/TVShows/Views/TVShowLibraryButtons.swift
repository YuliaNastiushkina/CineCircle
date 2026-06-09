import SwiftUI

struct TVShowBookmarkButton: View {
    let showID: Int
    let userID: String
    let title: String
    let posterPath: String?

    @State private var isSaved = false

    var body: some View {
        CircleButton(systemName: isSaved ? "bookmark.fill" : "bookmark", action: toggle)
            .foregroundStyle(isSaved ? AppUI.ColorPalette.accent : .white)
            .onAppear(perform: refresh)
            .onReceive(NotificationCenter.default.publisher(for: .tvShowLibraryDidChange)) { _ in
                refresh()
            }
    }

    private func toggle() {
        service.toggle(
            .saved,
            showID: showID,
            userID: userID,
            title: title,
            posterPath: posterPath
        )
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            refresh()
        }
    }

    private func refresh() {
        isSaved = service.isSet(.saved, showID: showID, userID: userID)
    }

    private let service = TVShowLibraryService()
}

struct TVShowSeenButton: View {
    let showID: Int
    let userID: String
    let title: String
    let posterPath: String?

    @State private var isSeen = false

    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(isSeen ? "Seen" : "Unseen")
                Image(systemName: "eye")
            }
            .font(Font.custom(AppUI.FontName.poppins, size: 16))
            .foregroundStyle(isSeen ? AppUI.ColorPalette.accent : .white)
        }
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: .tvShowLibraryDidChange)) { _ in
            refresh()
        }
    }

    private func toggle() {
        service.toggle(
            .seen,
            showID: showID,
            userID: userID,
            title: title,
            posterPath: posterPath
        )
        withAnimation {
            refresh()
        }
    }

    private func refresh() {
        isSeen = service.isSet(.seen, showID: showID, userID: userID)
    }

    private let service = TVShowLibraryService()
}
