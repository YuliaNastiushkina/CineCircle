import SwiftUI

struct TVEpisodesView: View {
    let showID: Int
    let showName: String
    let seasons: [RemoteTVSeasonSummary]
    let userID: String

    @State private var viewModel = TVSeasonViewModel()
    @State private var selectedSeasonNumber: Int
    @State private var watchedEpisodeIDs: Set<Int> = []

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
        Button {
            progressService.setWatched(
                !watchedEpisodeIDs.contains(episode.id),
                episodeID: episode.id,
                userID: userID,
                showID: showID
            )
            refreshProgress()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                episodeImage(episode)

                VStack(alignment: .leading, spacing: 6) {
                    Text("E\(episode.episodeNumber) · \(episode.name)")
                        .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 15))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let runtime = episode.runtime {
                        Text("\(runtime) min")
                            .font(Font.custom(AppUI.FontName.poppins, size: 12))
                            .foregroundStyle(.secondary)
                    }

                    if !episode.overview.isEmpty {
                        Text(episode.overview)
                            .font(Font.custom(AppUI.FontName.poppins, size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                Image(systemName: watchedEpisodeIDs.contains(episode.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(watchedEpisodeIDs.contains(episode.id) ? AppUI.ColorPalette.accent : .secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
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

    private let progressService = TVEpisodeProgressService()

    private static func initialSeason(from seasons: [RemoteTVSeasonSummary]) -> Int {
        seasons.first(where: { $0.seasonNumber > 0 && $0.episodeCount > 0 })?.seasonNumber
            ?? seasons.first(where: { $0.episodeCount > 0 })?.seasonNumber
            ?? 1
    }
}
