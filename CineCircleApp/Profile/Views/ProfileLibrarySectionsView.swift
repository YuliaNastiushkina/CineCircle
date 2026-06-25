import SwiftUI

struct ProfileLibrarySectionsView: View {
    let userId: String
    let watchedMovieIDs: [Int]
    let savedMovieIDs: [Int]
    let watchedMovies: [ProfileMovieSnapshot]
    let savedMovies: [ProfileMovieSnapshot]
    let seenTVShows: [TVShowLibraryRecord]
    let savedTVShows: [TVShowLibraryRecord]
    let trackedTVShows: [TVShowProgressRecord]
    let refreshToken: UUID

    @State private var displayedWatchedMovies: [ProfileMovieSnapshot] = []
    @State private var displayedSavedMovies: [ProfileMovieSnapshot] = []
    @State private var displayedSeenTVShows: [TVShowLibraryRecord] = []
    @State private var displayedTrackedShows: [ProfileTrackedTVShowItem] = []
    @State private var noteItems: [ProfileNoteItem] = []

    private let apiClient = APIClient()
    private let noteService = NoteService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
            trackedShowsSection

            mediaSection(
                title: "Watchlist",
                movies: displayedSavedMovies,
                tvShows: savedTVShows,
                emptyMessage: "Movies and TV shows you save will appear here."
            )

            mediaSection(
                title: "Recently watched",
                movies: displayedWatchedMovies,
                tvShows: displayedSeenTVShows,
                emptyMessage: "Movies and TV shows marked as watched will appear here."
            )

            notesSection
        }
        .task(id: refreshToken) {
            await loadSections()
        }
    }

    private var trackedShowsSection: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            sectionHeader(title: "Tracking") {
                ProfileTrackedTVShowsListView(shows: displayedTrackedShows)
            }

            if displayedTrackedShows.isEmpty {
                emptyCard(message: "Series you start tracking by marking episodes will appear here.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.movieCardSpacing) {
                        ForEach(displayedTrackedShows) { show in
                            NavigationLink {
                                TVShowDetailLoaderView(showID: show.id)
                            } label: {
                                ProfileTrackedTVShowCard(show: show)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Parameters.horizontalInset)
                }
            }
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
        async let loadedTrackedShows = loadTrackedShowItems()
        async let loadedNotes = loadNoteItems()

        let trackedShowResult = await loadedTrackedShows
        displayedWatchedMovies = await enrichedWatched
        displayedSavedMovies = await enrichedSaved
        displayedSeenTVShows = mergedSeenShows(with: trackedShowResult.completedShows)
        displayedTrackedShows = trackedShowResult.trackingShows
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

    private func mergedSeenShows(with completedShows: [TVShowLibraryRecord]) -> [TVShowLibraryRecord] {
        var recordsByID = Dictionary(uniqueKeysWithValues: seenTVShows.map { ($0.id, $0) })
        for show in completedShows where recordsByID[show.id] == nil {
            recordsByID[show.id] = show
        }
        return recordsByID.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func loadTrackedShowItems() async -> ProfileTrackedShowLoadResult {
        let progressRecords = Array(trackedTVShows.prefix(Parameters.previewMovieCount))
        var trackingShows: [ProfileTrackedTVShowItem] = []
        var completedShows: [TVShowLibraryRecord] = []

        for record in progressRecords {
            do {
                let detail = try await apiClient.fetch(
                    path: "tv/\(record.id)",
                    query: [:],
                    responseType: RemoteTVShowDetail.self
                )

                if detail.numberOfEpisodes > 0, record.watchedEpisodeCount >= detail.numberOfEpisodes {
                    let completedShow = TVShowLibraryRecord(
                        id: detail.id,
                        title: detail.name,
                        posterPath: detail.posterPath,
                        updatedAt: record.updatedAt == .distantPast ? Date() : record.updatedAt
                    )
                    completedShows.append(completedShow)
                    TVShowLibraryService().set(
                        .seen,
                        isSet: true,
                        showID: detail.id,
                        userID: userId,
                        title: detail.name,
                        posterPath: detail.posterPath
                    )
                    continue
                }

                trackingShows.append(
                    ProfileTrackedTVShowItem(
                        id: detail.id,
                        title: detail.name,
                        posterPath: detail.posterPath,
                        watchedEpisodeCount: record.watchedEpisodeCount,
                        totalEpisodeCount: detail.numberOfEpisodes,
                        updatedAt: record.updatedAt,
                        lastEpisodeCode: record.lastEpisodeCode
                    )
                )
            } catch {
                trackingShows.append(
                    ProfileTrackedTVShowItem(
                        id: record.id,
                        title: "TV Show #\(record.id)",
                        posterPath: nil,
                        watchedEpisodeCount: record.watchedEpisodeCount,
                        totalEpisodeCount: nil,
                        updatedAt: record.updatedAt,
                        lastEpisodeCode: record.lastEpisodeCode
                    )
                )
            }
        }

        return ProfileTrackedShowLoadResult(
            trackingShows: trackingShows.sorted { $0.updatedAt > $1.updatedAt },
            completedShows: completedShows
        )
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
        static let contentSpacing: CGFloat = 8
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
           let url = URL(string: "\(AppUI.TMDB.posterBase)\(posterPath)") {
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
        static let posterWidth = AppUI.PosterSize.standardWidth
        static let posterHeight = AppUI.PosterSize.standardHeight
        static let posterCornerRadius = AppUI.PosterSize.cornerRadius
        static let placeholderIconSize = AppUI.PosterSize.placeholderIconSize
        static let textSpacing = AppUI.Spacing.small
        static let titleFontSize = AppUI.FontSize.caption
        static let titleHeight: CGFloat = 32
        static let cardHeight: CGFloat = posterHeight + textSpacing + titleHeight
    }
}

private struct ProfileMediaPosterCard: View {
    let item: ProfileLibraryMediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.textSpacing) {
            Group {
                if let posterPath = item.posterPath,
                   let url = URL(string: "\(AppUI.TMDB.posterBase)\(posterPath)") {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        placeholder
                    }
                } else {
                    placeholder
                }
            }
            .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: Parameters.posterCornerRadius))
            .clipped()

            Text(item.title)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.titleFontSize))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: Parameters.posterWidth, height: Parameters.titleHeight, alignment: .topLeading)
        }
        .frame(width: Parameters.posterWidth, height: Parameters.cardHeight, alignment: .topLeading)
    }

    private var placeholder: some View {
        PosterPlaceholderView(cornerRadius: Parameters.posterCornerRadius, iconSize: Parameters.placeholderIconSize)
    }

    private enum Parameters {
        static let posterWidth = AppUI.PosterSize.standardWidth
        static let posterHeight = AppUI.PosterSize.standardHeight
        static let posterCornerRadius = AppUI.PosterSize.cornerRadius
        static let placeholderIconSize = AppUI.PosterSize.placeholderIconSize
        static let textSpacing = AppUI.Spacing.small
        static let titleFontSize = AppUI.FontSize.caption
        static let titleHeight: CGFloat = 32
        static let cardHeight: CGFloat = 190
    }
}

private struct ProfileTrackedShowLoadResult {
    let trackingShows: [ProfileTrackedTVShowItem]
    let completedShows: [TVShowLibraryRecord]
}

private struct ProfileTrackedTVShowItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let posterPath: String?
    let watchedEpisodeCount: Int
    let totalEpisodeCount: Int?
    let updatedAt: Date
    let lastEpisodeCode: String?

    var progressValue: Double {
        guard let totalEpisodeCount, totalEpisodeCount > 0 else { return 0 }
        return min(Double(watchedEpisodeCount) / Double(totalEpisodeCount), 1)
    }

    var progressText: String {
        guard let totalEpisodeCount, totalEpisodeCount > 0 else {
            return "\(watchedEpisodeCount) watched"
        }
        return "\(watchedEpisodeCount) of \(totalEpisodeCount) watched"
    }

    var subtitle: String? {
        guard let lastEpisodeCode else { return nil }
        return "Last: \(lastEpisodeCode)"
    }
}

private struct ProfileTrackedTVShowCard: View {
    let show: ProfileTrackedTVShowItem

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.textSpacing) {
            poster
                .frame(width: Parameters.cardWidth, height: Parameters.posterHeight)
                .clipShape(RoundedRectangle(cornerRadius: Parameters.posterCornerRadius))
                .clipped()

            Text(show.title)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.titleFontSize))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: Parameters.cardWidth, height: Parameters.titleHeight, alignment: .topLeading)

            VStack(alignment: .leading, spacing: Parameters.progressSpacing) {
                ProgressView(value: show.progressValue)
                    .tint(AppUI.ColorPalette.accent)
                    .frame(width: Parameters.cardWidth)

                Text(show.progressText)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.captionFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: Parameters.cardWidth, alignment: .leading)
            }
        }
        .frame(width: Parameters.cardWidth, height: Parameters.cardHeight, alignment: .topLeading)
    }

    @ViewBuilder
    private var poster: some View {
        if let posterPath = show.posterPath,
           let url = URL(string: "\(AppUI.TMDB.posterBase)\(posterPath)") {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholder
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        PosterPlaceholderView(cornerRadius: Parameters.posterCornerRadius, iconSize: Parameters.placeholderIconSize)
            .frame(width: Parameters.cardWidth, height: Parameters.posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: Parameters.posterCornerRadius))
    }

    private enum Parameters {
        static let cardWidth = AppUI.PosterSize.standardWidth
        static let posterHeight = AppUI.PosterSize.standardHeight
        static let posterCornerRadius = AppUI.PosterSize.cornerRadius
        static let placeholderIconSize = AppUI.PosterSize.placeholderIconSize
        static let textSpacing = AppUI.Spacing.small
        static let progressSpacing: CGFloat = 5
        static let titleFontSize = AppUI.FontSize.caption
        static let captionFontSize: CGFloat = 10
        static let titleHeight: CGFloat = 32
        static let cardHeight: CGFloat = posterHeight + textSpacing + titleHeight + 28
    }
}

private struct ProfileTrackedTVShowsListView: View {
    let shows: [ProfileTrackedTVShowItem]

    var body: some View {
        Group {
            if shows.isEmpty {
                ContentUnavailableView(
                    "No Tracked Shows",
                    systemImage: "play.tv",
                    description: Text("Series you start tracking by marking episodes will appear here.")
                )
            } else {
                List(shows) { show in
                    NavigationLink {
                        TVShowDetailLoaderView(showID: show.id)
                    } label: {
                        HStack(spacing: ListParameters.rowSpacing) {
                            poster(for: show)

                            VStack(alignment: .leading, spacing: ListParameters.textSpacing) {
                                Text(show.title)
                                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: ListParameters.titleFontSize))
                                    .lineLimit(2)

                                if let subtitle = show.subtitle {
                                    Text(subtitle)
                                        .font(Font.custom(AppUI.FontName.poppins, size: ListParameters.subtitleFontSize))
                                        .foregroundStyle(.secondary)
                                }

                                ProgressView(value: show.progressValue)
                                    .tint(AppUI.ColorPalette.accent)

                                Text(show.progressText)
                                    .font(Font.custom(AppUI.FontName.poppins, size: ListParameters.subtitleFontSize))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, ListParameters.rowVerticalPadding)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Tracking")
    }

    private func poster(for show: ProfileTrackedTVShowItem) -> some View {
        Group {
            if let path = show.posterPath,
               let url = URL(string: "\(AppUI.TMDB.posterBase)\(path)") {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: ListParameters.posterWidth, height: ListParameters.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: ListParameters.posterCornerRadius))
        .clipped()
    }

    private var placeholder: some View {
        PosterPlaceholderView(cornerRadius: ListParameters.posterCornerRadius, iconSize: ListParameters.placeholderIconSize)
    }

    private enum ListParameters {
        static let rowSpacing: CGFloat = 14
        static let rowVerticalPadding = AppUI.Spacing.xxSmall
        static let textSpacing: CGFloat = 7
        static let titleFontSize = AppUI.FontSize.subheadline
        static let subtitleFontSize = AppUI.FontSize.caption
        static let posterWidth = AppUI.PosterSize.compactWidth
        static let posterHeight = AppUI.PosterSize.compactHeight
        static let posterCornerRadius = AppUI.PosterSize.cornerRadius
        static let placeholderIconSize = AppUI.PosterSize.placeholderIconSize
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
            trackedTVShows: [
                TVShowProgressRecord(
                    id: 1399,
                    watchedEpisodeCount: 12,
                    updatedAt: .now,
                    lastSeasonNumber: 2,
                    lastEpisodeNumber: 3
                ),
            ],
            refreshToken: UUID()
        )
        .padding()
    }
}
