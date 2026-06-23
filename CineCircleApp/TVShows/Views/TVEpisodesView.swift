import SwiftUI

struct TVEpisodesView: View {
    let showID: Int
    let showName: String
    let seasons: [RemoteTVSeasonSummary]
    let userID: String

    @State private var viewModel = TVSeasonViewModel()
    @State private var selectedSeasonNumber: Int
    @State private var watchedEpisodeIDs: Set<Int> = []
    @State private var diaryEntryEpisodeIDs: Set<Int> = []
    @State private var selectedEpisodeForDetail: RemoteTVEpisode?

    init(showID: Int, showName: String, seasons: [RemoteTVSeasonSummary], userID: String) {
        self.showID = showID
        self.showName = showName
        self.seasons = seasons.filter { $0.episodeCount > 0 }
        self.userID = userID
        _selectedSeasonNumber = State(initialValue: Self.initialSeason(from: seasons))
    }

    var body: some View {
        VStack(spacing: 0) {
            seasonPicker
            seasonProgress

            if viewModel.isLoading {
                ProgressView("Loading episodes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.episodes.isEmpty {
                ContentUnavailableView("No Episodes Found", systemImage: "play.rectangle")
            } else {
                List(viewModel.episodes) { episode in
                    episodeRow(episode)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(showName)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedSeasonNumber) {
            watchedEpisodeIDs = progressService.watchedEpisodeIDs(userID: userID, showID: showID)
            await viewModel.fetchSeason(showID: showID, seasonNumber: selectedSeasonNumber)
            refreshDiaryEntries()
        }
        .sheet(item: $selectedEpisodeForDetail, onDismiss: refreshDiaryEntries) { episode in
            NavigationStack {
                TVEpisodeDetailView(
                    showID: showID,
                    showName: showName,
                    userID: userID,
                    episode: episode,
                    isWatched: watchedEpisodeIDs.contains(episode.id),
                    hasDiaryEntry: diaryEntryEpisodeIDs.contains(episode.id),
                    onWatchedChange: { watched in
                        progressService.setWatched(
                            watched,
                            episodeID: episode.id,
                            userID: userID,
                            showID: showID
                        )
                        refreshProgress()
                    },
                    onDiarySave: {
                        progressService.setWatched(
                            true,
                            episodeID: episode.id,
                            userID: userID,
                            showID: showID
                        )
                        refreshProgress()
                        refreshDiaryEntries()
                    }
                )
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var seasonPicker: some View {
        Picker("Season", selection: $selectedSeasonNumber) {
            ForEach(seasons) { season in
                Text(season.name).tag(season.seasonNumber)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var seasonProgress: some View {
        let watchedCount = viewModel.episodes.filter { watchedEpisodeIDs.contains($0.id) }.count
        let allWatched = !viewModel.episodes.isEmpty && watchedCount == viewModel.episodes.count

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(watchedCount) of \(viewModel.episodes.count) watched")
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 14))
                ProgressView(value: Double(watchedCount), total: Double(max(viewModel.episodes.count, 1)))
                    .tint(AppUI.ColorPalette.accent)
            }

            Button(allWatched ? "Clear" : "Mark all") {
                let episodeIDs = viewModel.episodes.map(\.id)
                progressService.setSeasonWatched(
                    !allWatched,
                    episodeIDs: episodeIDs,
                    userID: userID,
                    showID: showID
                )
                refreshProgress()
            }
            .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 13))
        }
        .padding()
        .background(AppUI.ColorPalette.secondarySurface)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.medium))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func episodeRow(_ episode: RemoteTVEpisode) -> some View {
        let isWatched = watchedEpisodeIDs.contains(episode.id)
        let hasDiaryEntry = diaryEntryEpisodeIDs.contains(episode.id)

        return HStack(alignment: .top, spacing: 12) {
            Button {
                selectedEpisodeForDetail = episode
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    episodeImage(episode)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("E\(episode.episodeNumber) · \(episode.name)")
                            .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 15))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            if let runtime = episode.runtime {
                                Text("\(runtime) min")
                            }

                            diaryStatusPill(hasDiaryEntry: hasDiaryEntry)
                        }
                        .font(Font.custom(AppUI.FontName.poppins, size: 12))
                        .foregroundStyle(.secondary)

                        if !episode.overview.isEmpty {
                            Text(episode.overview)
                                .font(Font.custom(AppUI.FontName.poppins, size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                progressService.setWatched(
                    !isWatched,
                    episodeID: episode.id,
                    userID: userID,
                    showID: showID
                )
                refreshProgress()
            } label: {
                Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isWatched ? AppUI.ColorPalette.accent : .secondary)
                    .frame(width: 44, height: 44, alignment: .topTrailing)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func diaryStatusPill(hasDiaryEntry: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: hasDiaryEntry ? "book.closed.fill" : "sparkles")
                .font(.system(size: 11, weight: .semibold))

            Text(hasDiaryEntry ? "Diary" : "Reflect")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 11))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(AppUI.ColorPalette.accent.opacity(hasDiaryEntry ? 1 : 0.75))
        .clipShape(Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }

    private func episodeImage(_ episode: RemoteTVEpisode) -> some View {
        Group {
            if let path = episode.stillPath,
               let url = URL(string: "https://image.tmdb.org/t/p/w300\(path)") {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.15)
                }
            } else {
                Color.secondary.opacity(0.15)
                    .overlay(Image(systemName: "play.rectangle").foregroundStyle(.secondary))
            }
        }
        .frame(width: 112, height: 63)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .clipped()
    }

    private func refreshProgress() {
        watchedEpisodeIDs = progressService.watchedEpisodeIDs(userID: userID, showID: showID)
    }

    private func refreshDiaryEntries() {
        diaryEntryEpisodeIDs = NoteService.shared.tvEpisodeDiaryEntryIDs(showId: showID, userId: userID)
    }

    private func diaryTarget(for episode: RemoteTVEpisode) -> MovieDiaryEntryTarget {
        .tvEpisode(
            showId: showID,
            episodeId: episode.id,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber
        )
    }

    private let progressService = TVEpisodeProgressService()

    private static func initialSeason(from seasons: [RemoteTVSeasonSummary]) -> Int {
        seasons.first(where: { $0.seasonNumber > 0 && $0.episodeCount > 0 })?.seasonNumber
            ?? seasons.first(where: { $0.episodeCount > 0 })?.seasonNumber
            ?? 1
    }
}

private struct TVEpisodeDetailView: View {
    let showID: Int
    let showName: String
    let userID: String
    let episode: RemoteTVEpisode
    let isWatched: Bool
    let hasDiaryEntry: Bool
    let onWatchedChange: (Bool) -> Void
    let onDiarySave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isPresentingDiary = false
    @State private var currentIsWatched: Bool
    @State private var currentHasDiaryEntry: Bool

    init(
        showID: Int,
        showName: String,
        userID: String,
        episode: RemoteTVEpisode,
        isWatched: Bool,
        hasDiaryEntry: Bool,
        onWatchedChange: @escaping (Bool) -> Void,
        onDiarySave: @escaping () -> Void
    ) {
        self.showID = showID
        self.showName = showName
        self.userID = userID
        self.episode = episode
        self.isWatched = isWatched
        self.hasDiaryEntry = hasDiaryEntry
        self.onWatchedChange = onWatchedChange
        self.onDiarySave = onDiarySave
        _currentIsWatched = State(initialValue: isWatched)
        _currentHasDiaryEntry = State(initialValue: hasDiaryEntry)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
                episodeHero
                episodeMetadata
                diaryButton
                overviewSection
            }
            .padding(Parameters.contentPadding)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Episode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isPresentingDiary, onDismiss: refreshDiaryState) {
            MovieDiaryView(
                target: diaryTarget,
                userId: userID,
                title: episode.name,
                subtitle: "S\(episode.seasonNumber) E\(episode.episodeNumber) · \(showName)",
                parentTitle: showName,
                navigationTitle: "Episode Diary",
                onSave: {
                    currentIsWatched = true
                    currentHasDiaryEntry = true
                    onDiarySave()
                }
            )
        }
    }

    private var episodeHero: some View {
        VStack(alignment: .leading, spacing: Parameters.titleSpacing) {
            episodeImage

            Text("S\(episode.seasonNumber) E\(episode.episodeNumber)")
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.captionFontSize))
                .foregroundStyle(.secondary)

            Text(episode.name)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var episodeImage: some View {
        Group {
            if let path = episode.stillPath,
               let url = URL(string: "https://image.tmdb.org/t/p/w780\(path)") {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderImage
                }
            } else {
                placeholderImage
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
        .clipped()
    }

    private var placeholderImage: some View {
        AppUI.ColorPalette.softCardBackground
            .overlay {
                Image(systemName: "play.rectangle")
                    .font(.system(size: Parameters.placeholderIconSize))
                    .foregroundStyle(.secondary)
            }
    }

    private var episodeMetadata: some View {
        HStack(spacing: Parameters.metadataSpacing) {
            if let runtime = episode.runtime {
                metadataChip("\(runtime) min")
            }

            Button {
                currentIsWatched.toggle()
                onWatchedChange(currentIsWatched)
            } label: {
                Label(currentIsWatched ? "Watched" : "Mark watched", systemImage: currentIsWatched ? "checkmark.circle.fill" : "circle")
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.chipFontSize))
                    .foregroundStyle(currentIsWatched ? .black : .primary)
                    .padding(.horizontal, Parameters.chipHorizontalPadding)
                    .padding(.vertical, Parameters.chipVerticalPadding)
                    .background(currentIsWatched ? AppUI.ColorPalette.accent : AppUI.ColorPalette.softCardBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var diaryButton: some View {
        Button {
            isPresentingDiary = true
        } label: {
            Label(currentHasDiaryEntry ? "Revisit reflection" : "Reflect on this episode", systemImage: "book.closed")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.buttonFontSize))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Parameters.buttonVerticalPadding)
                .background(AppUI.ColorPalette.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: Parameters.overviewSpacing) {
            Text("Overview")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.sectionTitleFontSize))
                .foregroundStyle(.primary)

            Text(episode.overview.isEmpty ? "No overview available." : episode.overview)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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

    private func refreshDiaryState() {
        currentHasDiaryEntry = !NoteService.shared.fetchDiaryEntries(for: diaryTarget, userId: userID).isEmpty
    }

    private var diaryTarget: MovieDiaryEntryTarget {
        .tvEpisode(
            showId: showID,
            episodeId: episode.id,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber
        )
    }

    private enum Parameters {
        static let contentPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 20
        static let titleSpacing: CGFloat = 8
        static let metadataSpacing: CGFloat = 8
        static let overviewSpacing: CGFloat = 8
        static let buttonVerticalPadding: CGFloat = 14
        static let chipHorizontalPadding: CGFloat = 10
        static let chipVerticalPadding: CGFloat = 6
        static let titleFontSize: CGFloat = 22
        static let sectionTitleFontSize: CGFloat = 16
        static let bodyFontSize: CGFloat = 14
        static let captionFontSize: CGFloat = 13
        static let chipFontSize: CGFloat = 12
        static let buttonFontSize: CGFloat = 15
        static let placeholderIconSize: CGFloat = 30
    }
}
