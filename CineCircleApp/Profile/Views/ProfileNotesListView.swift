import SwiftUI

/// Displays all movie diary entries for a user. Tapping an entry navigates to the movie detail.
struct ProfileNotesListView: View {
    let userId: String

    @State private var entries: [MovieDiary] = []
    @State private var movieTitles: [Int: String] = [:]
    @State private var isLoading = true

    private let noteService = NoteService.shared
    private let apiClient = APIClient()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading diary...")
            } else if entries.isEmpty {
                ContentUnavailableView(
                    "No Diary Entries",
                    systemImage: "book.closed",
                    description: Text("Private movie reflections you write will appear here.")
                )
            } else {
                List(entries, id: \.objectID) { entry in
                    NavigationLink {
                        MovieDetailViewLoaderView(movieID: Int(entry.movieID))
                    } label: {
                        DiaryEntryRow(
                            entry: entry,
                            movieTitle: movieTitles[Int(entry.movieID)]
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Diary")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadEntries()
        }
    }

    private func loadEntries() async {
        isLoading = true
        entries = noteService.allNotes(for: userId)

        let uniqueIDs = Set(
            entries
                .filter { ($0.movieTitle ?? "").isEmpty }
                .map { Int($0.movieID) }
        )
        for id in uniqueIDs {
            do {
                let detail = try await apiClient.fetch(
                    path: "movie/\(id)",
                    query: [:],
                    responseType: RemoteMovieDetail.self
                )
                movieTitles[id] = detail.title
            } catch {
                movieTitles[id] = "Movie #\(id)"
            }
        }
        isLoading = false
    }
}

private struct DiaryEntryRow: View {
    let entry: MovieDiary
    let movieTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            Text(entry.movieTitle ?? movieTitle ?? "Movie #\(entry.movieID)")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .foregroundColor(.primary)

            if let reflection = entry.content, !reflection.isEmpty {
                Text(reflection)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            LazyVGrid(columns: Parameters.metadataColumns, alignment: .leading, spacing: Parameters.metaSpacing) {
                ForEach(moodTitles, id: \.self) { moodTitle in
                    metadataChip(moodTitle)
                }

                metadataChip(watchTypeTitle)
                metadataChip(watchedWithTitle)

                if entry.hasSpoilers {
                    metadataChip("Spoilers")
                }
            }

            Text(entry.watchedDate ?? entry.createdAt ?? .now, style: .date)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.dateFontSize))
                .foregroundColor(.secondary.opacity(Parameters.dateOpacity))
        }
        .padding(.vertical, Parameters.verticalPadding)
    }

    private var moodTitles: [String] {
        MovieDiaryMood.decoded(from: entry.mood).map(\.title)
    }

    private var watchTypeTitle: String {
        MovieDiaryWatchType(rawValue: entry.watchType ?? "")?.title ?? MovieDiaryWatchType.firstWatch.title
    }

    private var watchedWithTitle: String {
        let option = MovieDiaryWatchedWith(rawValue: entry.watchedWith ?? "") ?? .alone
        return "With: \(option.title)"
    }

    private func metadataChip(_ title: String) -> some View {
        Text(title)
            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.chipFontSize))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Parameters.chipHorizontalPadding)
            .padding(.vertical, Parameters.chipVerticalPadding)
            .background(AppUI.ColorPalette.softCardBackground)
            .clipShape(Capsule())
    }

    private enum Parameters {
        static let contentSpacing: CGFloat = 6
        static let metaSpacing: CGFloat = 6
        static let verticalPadding: CGFloat = 4
        static let titleFontSize: CGFloat = 14
        static let bodyFontSize: CGFloat = 13
        static let dateFontSize: CGFloat = 11
        static let chipFontSize: CGFloat = 11
        static let chipHorizontalPadding: CGFloat = 8
        static let chipVerticalPadding: CGFloat = 4
        static let dateOpacity: Double = 0.7
        static let metadataColumns = [GridItem(.adaptive(minimum: 88), spacing: metaSpacing)]
    }
}

#Preview {
    NavigationStack {
        ProfileNotesListView(userId: "previewUser")
    }
}
