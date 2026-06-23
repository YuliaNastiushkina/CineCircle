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
            sectionHeader(title: "Diary") {
                ProfileNotesListView(userId: userId)
            }

            if noteItems.isEmpty {
                emptyCard(message: "Private movie and episode diary entries will appear here.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.noteCardSpacing) {
                        ForEach(noteItems) { item in
                            if item.mediaType == .movie {
                                NavigationLink {
                                    MovieDetailViewLoaderView(movieID: item.movieID)
                                } label: {
                                    ProfileNotePreviewCard(item: item)
                                }
                                .buttonStyle(.plain)
                            } else {
                                ProfileNotePreviewCard(item: item)
                            }
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
                .filter { $0.diaryMediaType == .movie && ($0.movieTitle ?? "").isEmpty }
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
                mediaType: note.diaryMediaType,
                movieID: movieID,
                title: note.diaryMediaType == .movie
                    ? note.movieTitle ?? titlesByID[movieID] ?? "Movie #\(movieID)"
                    : note.diaryDisplayTitle,
                subtitle: note.diarySubtitle,
                content: note.content ?? "",
                createdAt: note.createdAt,
                watchedDate: note.watchedDate,
                moods: MovieDiaryMood.decoded(from: note.mood),
                watchType: MovieDiaryWatchType(rawValue: note.watchType ?? "") ?? .firstWatch,
                watchedWith: MovieDiaryWatchedWith(rawValue: note.watchedWith ?? "") ?? .alone,
                hasSpoilers: note.hasSpoilers
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
    let mediaType: MovieDiaryMediaType
    let movieID: Int
    let title: String
    let subtitle: String?
    let content: String
    let createdAt: Date?
    let watchedDate: Date?
    let moods: [MovieDiaryMood]
    let watchType: MovieDiaryWatchType
    let watchedWith: MovieDiaryWatchedWith
    let hasSpoilers: Bool
}

private struct ProfileNotePreviewCard: View {
    let item: ProfileNoteItem

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            Text(item.title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            LazyVGrid(columns: Parameters.metadataColumns, alignment: .leading, spacing: Parameters.metaSpacing) {
                ForEach(Array(item.moods.prefix(Parameters.previewMoodCount)), id: \.self) { mood in
                    metadataChip(mood.title)
                }

                metadataChip(item.watchType.title)
                metadataChip("With: \(item.watchedWith.title)")

                if item.hasSpoilers {
                    metadataChip("Spoilers")
                }
            }

            if !item.content.isEmpty {
                Text(item.content)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if let date = item.watchedDate ?? item.createdAt {
                Text(date, style: .date)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.dateFontSize))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: Parameters.cardWidth, height: Parameters.cardHeight, alignment: .topLeading)
        .padding(Parameters.cardPadding)
        .background(AppUI.ColorPalette.softCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
    }

    private func metadataChip(_ title: String) -> some View {
        Text(title)
            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.chipFontSize))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Parameters.chipHorizontalPadding)
            .padding(.vertical, Parameters.chipVerticalPadding)
            .background(Color(.systemBackground))
            .clipShape(Capsule())
    }

    private enum Parameters {
        static let cardWidth: CGFloat = 240
        static let cardHeight: CGFloat = 160
        static let cardPadding: CGFloat = 14
        static let contentSpacing: CGFloat = 8
        static let metaSpacing: CGFloat = 6
        static let titleFontSize: CGFloat = 14
        static let subtitleFontSize: CGFloat = 11
        static let bodyFontSize: CGFloat = 12
        static let dateFontSize: CGFloat = 11
        static let chipFontSize: CGFloat = 10
        static let previewMoodCount = 2
        static let chipHorizontalPadding: CGFloat = 7
        static let chipVerticalPadding: CGFloat = 3
        static let metadataColumns = [GridItem(.adaptive(minimum: 88), spacing: metaSpacing)]
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
