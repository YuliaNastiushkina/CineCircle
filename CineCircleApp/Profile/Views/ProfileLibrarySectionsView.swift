import SwiftUI

struct ProfileLibrarySectionsView: View {
    let userId: String
    let watchedMovieIDs: [Int]
    let savedMovieIDs: [Int]
    let watchedMovies: [ProfileMovieSnapshot]
    let savedMovies: [ProfileMovieSnapshot]
    let refreshToken: UUID

    @State private var displayedWatchedMovies: [ProfileMovieSnapshot] = []
    @State private var displayedSavedMovies: [ProfileMovieSnapshot] = []
    @State private var noteItems: [ProfileNoteItem] = []

    private let apiClient = APIClient()
    private let noteService = NoteService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
            movieSection(
                title: "Recently watched",
                movieIDs: watchedMovieIDs,
                movies: displayedWatchedMovies,
                emptyMessage: "Movies marked as watched will appear here.",
                destinationTitle: "Watched"
            )

            movieSection(
                title: "Saved",
                movieIDs: savedMovieIDs,
                movies: displayedSavedMovies,
                emptyMessage: "Movies you save will appear here.",
                destinationTitle: "Saved"
            )

            notesSection
        }
        .task(id: refreshToken) {
            await loadSections()
        }
    }

    @ViewBuilder private func movieSection(
        title: String,
        movieIDs: [Int],
        movies: [ProfileMovieSnapshot],
        emptyMessage: String,
        destinationTitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            sectionHeader(title: title) {
                ProfileMovieListView(title: destinationTitle, movieIDs: movieIDs)
            }

            if movies.isEmpty {
                emptyCard(message: emptyMessage)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.movieCardSpacing) {
                        ForEach(movies) { movie in
                            NavigationLink {
                                MovieDetailViewLoaderView(movieID: movie.id)
                            } label: {
                                ProfileMoviePosterCard(movie: movie)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Parameters.horizontalInset)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            sectionHeader(title: "Notes") {
                ProfileNotesListView(userId: userId)
            }

            if noteItems.isEmpty {
                emptyCard(message: "Notes you write for movies will appear here.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.noteCardSpacing) {
                        ForEach(noteItems) { item in
                            NavigationLink {
                                MovieDetailViewLoaderView(movieID: item.movieID)
                            } label: {
                                ProfileNotePreviewCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Parameters.horizontalInset)
                }
            }
        }
    }

    private func sectionHeader(title: String, @ViewBuilder destination: () -> some View) -> some View {
        HStack {
            Text(title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.sectionTitleFontSize))
                .foregroundColor(.primary)

            Spacer()

            NavigationLink {
                destination()
            } label: {
                Text("See all")
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.sectionActionFontSize))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func emptyCard(message: String) -> some View {
        Text(message)
            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.emptyMessageFontSize))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Parameters.emptyCardPadding)
            .background(AppUI.ColorPalette.softCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
    }

    private func loadSections() async {
        let watchedPreview = Array(watchedMovies.prefix(Parameters.previewMovieCount))
        let savedPreview = Array(savedMovies.prefix(Parameters.previewMovieCount))

        async let enrichedWatched = enrichMovies(watchedPreview)
        async let enrichedSaved = enrichMovies(savedPreview)
        async let loadedNotes = loadNoteItems()

        displayedWatchedMovies = await enrichedWatched
        displayedSavedMovies = await enrichedSaved
        noteItems = await loadedNotes
    }

    private func enrichMovies(_ movies: [ProfileMovieSnapshot]) async -> [ProfileMovieSnapshot] {
        var enrichedMovies = movies

        for index in enrichedMovies.indices {
            guard needsEnrichment(enrichedMovies[index]) else { continue }

            do {
                let detail = try await apiClient.fetch(
                    path: "movie/\(enrichedMovies[index].id)",
                    query: [:],
                    responseType: RemoteMovieDetail.self
                )

                enrichedMovies[index] = ProfileMovieSnapshot(
                    id: detail.id,
                    title: detail.title,
                    posterPath: detail.posterPath,
                    createdAt: enrichedMovies[index].createdAt
                )
            } catch {
                continue
            }
        }

        return enrichedMovies
    }

    private func needsEnrichment(_ movie: ProfileMovieSnapshot) -> Bool {
        movie.posterPath == nil || movie.title == "Movie #\(movie.id)"
    }

    private func loadNoteItems() async -> [ProfileNoteItem] {
        let notes = Array(noteService.allNotes(for: userId).prefix(Parameters.previewNoteCount))
        let ids = Set(
            notes
                .filter { ($0.movieTitle ?? "").isEmpty }
                .map { Int($0.movieID) }
        )
        var titlesByID: [Int: String] = [:]

        for id in ids {
            do {
                let detail = try await apiClient.fetch(
                    path: "movie/\(id)",
                    query: [:],
                    responseType: RemoteMovieDetail.self
                )
                titlesByID[id] = detail.title
            } catch {
                titlesByID[id] = "Movie #\(id)"
            }
        }

        return notes.map { note in
            let movieID = Int(note.movieID)
            return ProfileNoteItem(
                id: note.objectID.uriRepresentation().absoluteString,
                movieID: movieID,
                movieTitle: note.movieTitle ?? titlesByID[movieID] ?? "Movie #\(movieID)",
                content: note.content ?? "",
                createdAt: note.createdAt
            )
        }
    }

    private enum Parameters {
        static let sectionSpacing: CGFloat = 28
        static let contentSpacing: CGFloat = 12
        static let horizontalInset: CGFloat = 2
        static let movieCardSpacing: CGFloat = 12
        static let noteCardSpacing: CGFloat = 12
        static let sectionTitleFontSize: CGFloat = 18
        static let sectionActionFontSize: CGFloat = 12
        static let emptyMessageFontSize: CGFloat = 13
        static let emptyCardPadding: CGFloat = 16
        static let previewMovieCount = 10
        static let previewNoteCount = 10
    }
}

private struct ProfileMoviePosterCard: View {
    let movie: ProfileMovieSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.textSpacing) {
            poster

            Text(movie.title)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.titleFontSize))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: Parameters.posterWidth, alignment: .leading)
                .frame(height: Parameters.titleHeight, alignment: .topLeading)
        }
        .frame(width: Parameters.posterWidth, height: Parameters.cardHeight, alignment: .topLeading)
    }

    @ViewBuilder
    private var poster: some View {
        if let posterPath = movie.posterPath,
           let url = URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: Parameters.posterCornerRadius))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        PosterPlaceholderView(
            cornerRadius: Parameters.posterCornerRadius,
            iconSize: Parameters.placeholderIconSize
        )
        .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
    }

    private enum Parameters {
        static let posterWidth: CGFloat = 100
        static let posterHeight: CGFloat = 150
        static let posterCornerRadius: CGFloat = 12
        static let placeholderIconSize: CGFloat = 20
        static let textSpacing: CGFloat = 8
        static let titleFontSize: CGFloat = 12
        static let titleHeight: CGFloat = 32
        static let cardHeight: CGFloat = posterHeight + textSpacing + titleHeight
    }
}

private struct ProfileNoteItem: Identifiable {
    let id: String
    let movieID: Int
    let movieTitle: String
    let content: String
    let createdAt: Date?
}

private struct ProfileNotePreviewCard: View {
    let item: ProfileNoteItem

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            Text(item.movieTitle)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(item.content)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                .foregroundStyle(.secondary)
                .lineLimit(4)

            if let createdAt = item.createdAt {
                Text(createdAt, style: .date)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.dateFontSize))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: Parameters.cardWidth, height: Parameters.cardHeight, alignment: .topLeading)
        .padding(Parameters.cardPadding)
        .background(AppUI.ColorPalette.softCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
    }

    private enum Parameters {
        static let cardWidth: CGFloat = 220
        static let cardHeight: CGFloat = 140
        static let cardPadding: CGFloat = 14
        static let contentSpacing: CGFloat = 8
        static let titleFontSize: CGFloat = 14
        static let bodyFontSize: CGFloat = 12
        static let dateFontSize: CGFloat = 11
    }
}

#Preview {
    NavigationStack {
        ProfileLibrarySectionsView(
            userId: "previewUser",
            watchedMovieIDs: [550, 680],
            savedMovieIDs: [13],
            watchedMovies: [
                ProfileMovieSnapshot(id: 550, title: "Fight Club", posterPath: nil, createdAt: .now),
                ProfileMovieSnapshot(id: 680, title: "Pulp Fiction", posterPath: nil, createdAt: .now),
            ],
            savedMovies: [
                ProfileMovieSnapshot(id: 13, title: "Forrest Gump", posterPath: nil, createdAt: .now),
            ],
            refreshToken: UUID()
        )
        .padding()
    }
}
