import SwiftUI

/// Displays all movie notes for a user. Tapping a note navigates to the movie detail.
struct ProfileNotesListView: View {
    let userId: String

    @State private var notes: [MovieNote] = []
    @State private var movieTitles: [Int: String] = [:]
    @State private var isLoading = true

    private let noteService = NoteService.shared
    private let apiClient = APIClient()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading notes...")
            } else if notes.isEmpty {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "note.text",
                    description: Text("Notes you write on movies will appear here.")
                )
            } else {
                List(notes, id: \.objectID) { note in
                    NavigationLink {
                        MovieDetailViewLoaderView(movieID: Int(note.movieID))
                    } label: {
                        NoteRow(
                            note: note,
                            movieTitle: movieTitles[Int(note.movieID)]
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Notes")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadNotes()
        }
    }

    private func loadNotes() async {
        isLoading = true
        notes = noteService.allNotes(for: userId)

        // Fetch movie titles for each note
        let uniqueIDs = Set(notes.map { Int($0.movieID) })
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

// MARK: - Note Row

private struct NoteRow: View {
    let note: MovieNote
    let movieTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(movieTitle ?? "Movie #\(note.movieID)")
                .font(Font.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(.primary)

            Text(note.content ?? "")
                .font(Font.custom("Poppins", size: 13))
                .foregroundColor(.secondary)
                .lineLimit(3)

            if let date = note.createdAt {
                Text(date, style: .date)
                    .font(Font.custom("Poppins", size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ProfileNotesListView(userId: "previewUser")
    }
}
