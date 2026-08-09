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
        let request = ProfileLibrarySectionLoadRequest(
            watchedMovies: watchedMovies,
            savedMovies: savedMovies,
            seenTVShows: seenTVShows,
            trackedTVShows: trackedTVShows,
            previewMovieCount: Parameters.previewMovieCount,
            previewNoteCount: Parameters.previewNoteCount
        )
        let snapshot = await ProfileLibrarySectionLoader(userId: userId).loadSections(request)

        displayedWatchedMovies = snapshot.watchedMovies
        displayedSavedMovies = snapshot.savedMovies
        displayedSeenTVShows = snapshot.seenTVShows
        displayedTrackedShows = snapshot.trackedShows
        noteItems = snapshot.noteItems
    }

    private enum Parameters {
        static let sectionSpacing: CGFloat = 28
        static let contentSpacing = AppUI.Spacing.small
        static let horizontalInset: CGFloat = 2
        static let movieCardSpacing = AppUI.Spacing.medium
        static let noteCardSpacing = AppUI.Spacing.medium
        static let sectionTitleFontSize: CGFloat = 18
        static let sectionActionFontSize = AppUI.FontSize.caption
        static let emptyMessageFontSize = AppUI.FontSize.footnote
        static let emptyCardPadding = AppUI.Spacing.large
        static let previewMovieCount = 10
        static let previewNoteCount = 10
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
