import SwiftUI

struct ProfileLibrarySectionsView: View {
    let userId: String
    let watchedMovieIDs: [Int]
    let savedMovieIDs: [Int]
    let watchedMovies: [ProfileMovieSnapshot]
    let savedMovies: [ProfileMovieSnapshot]
    let seenTVShows: [TVShowLibraryRecord]
    let savedTVShows: [TVShowLibraryRecord]
    let refreshToken: UUID

    @State private var displayedWatchedMovies: [ProfileMovieSnapshot] = []
    @State private var displayedSavedMovies: [ProfileMovieSnapshot] = []
    @State private var noteItems: [ProfileNoteItem] = []

    private let apiClient = APIClient()
    private let noteService = NoteService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
            mediaSection(
                title: "Recently watched",
                movies: displayedWatchedMovies,
                tvShows: seenTVShows,
                emptyMessage: "Movies and TV shows marked as watched will appear here."
            )

            mediaSection(
                title: "Saved",
                movies: displayedSavedMovies,
                tvShows: savedTVShows,
                emptyMessage: "Movies and TV shows you save will appear here."
            )

            notesSection
        }
        .task(id: refreshToken) {
            await loadSections()
        }
    }

    @ViewBuilder private func mediaSection(
        title: String,
        movies: [ProfileMovieSnapshot],
        tvShows: [TVShowLibraryRecord],
        emptyMessage: String
    ) -> some View {
        let items = Array(
            (movies.map(ProfileLibraryMediaItem.movie) + tvShows.map(ProfileLibraryMediaItem.tvShow))
                .sorted { $0.date > $1.date }
                .prefix(Parameters.previewMovieCount)
        )

        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            sectionHeader(title: title) {
                ProfileMediaListView(title: title, movies: movies, tvShows: tvShows)
            }

            if items.isEmpty {
                emptyCard(message: emptyMessage)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.movieCardSpacing) {
                        ForEach(items) { item in
                            NavigationLink {
                                mediaDestination(for: item)
                            } label: {
                                ProfileMediaPosterCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Parameters.horizontalInset)
                }
            }
        }
    }

    @ViewBuilder private func mediaDestination(for item: ProfileLibraryMediaItem) -> some View {
        switch item {
        case let .movie(movie):
            MovieDetailViewLoaderView(movieID: movie.id)
        case let .tvShow(show):
            TVShowDetailLoaderView(showID: show.id)
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

private struct ProfileMediaPosterCard: View {
    let item: ProfileLibraryMediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let posterPath = item.posterPath,
                   let url = URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)") {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        placeholder
                    }
                } else {
                    placeholder
                }
            }
            .frame(width: 100, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .clipped()

            Text(item.title)
                .font(Font.custom(AppUI.FontName.poppins, size: 12))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 100, height: 32, alignment: .topLeading)
        }
        .frame(width: 100, height: 190, alignment: .topLeading)
    }

    private var placeholder: some View {
        PosterPlaceholderView(cornerRadius: 12, iconSize: 20)
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
            seenTVShows: [],
            savedTVShows: [],
            refreshToken: UUID()
        )
        .padding()
    }
}
