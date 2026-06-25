import SwiftUI

struct TVShowDetailLoaderView: View {
    let showID: Int
    @State private var viewModel = TVShowDetailViewModel()

    var body: some View {
        Group {
            if let show = viewModel.show {
                TVShowScreenView(show: show)
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(
                    "Unable to Load TV Show",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.fetchShow(id: showID)
        }
    }
}

private struct TVShowScreenView: View {
    let show: RemoteTVShowDetail

    @EnvironmentObject private var userSession: UserSession

    var body: some View {
        MediaDetailContainer { dismiss in
            MediaPosterHeaderView(
                posterPath: show.posterPath,
                rating: show.voteAverage,
                onDismiss: dismiss
            ) {
                if case let .authenticated(userID) = userSession.authState {
                    TVShowBookmarkButton(
                        showID: show.id,
                        userID: userID,
                        title: show.name,
                        posterPath: show.posterPath
                    )
                }
            } bottomTrailing: {
                if case let .authenticated(userID) = userSession.authState {
                    TVShowSeenButton(
                        showID: show.id,
                        userID: userID,
                        title: show.name,
                        posterPath: show.posterPath
                    )
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(white: 0.32).opacity(0.8))
                    .clipShape(Capsule())
                }
            }
        } content: {
            TVShowInfoView(show: show)
        }
    }
}

private struct TVShowInfoView: View {
    let show: RemoteTVShowDetail

    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var userSession: UserSession
    @State private var expanded = false
    @State private var watchedCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.baseSpacing) {
            titleSection
            metadata

            if let tagline = show.tagline?.trimmingCharacters(in: .whitespacesAndNewlines), !tagline.isEmpty {
                Text(tagline)
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.taglineFontSize))
                    .foregroundStyle(AppUI.ColorPalette.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Parameters.taglineTopPadding)
            }

            overviewSection
                .padding(.top, Parameters.overviewTopPadding)

            if case let .authenticated(userID) = userSession.authState {
                TVShowEpisodeProgressCard(show: show, userID: userID, watchedCount: watchedCount)
                    .padding(.top, Parameters.largeSectionSpacing)
            }

            trailerSection
            gallerySection
            seasonsSection
            castSection
            crewSection
            tvShowInfoSection
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .onAppear(perform: refreshProgress)
        .onReceive(NotificationCenter.default.publisher(for: .tvEpisodeProgressDidChange)) { notification in
            guard notification.userInfo?["showID"] as? Int == show.id else { return }
            refreshProgress()
        }
    }

    private var titleSection: some View {
        HStack(alignment: .top) {
            Text(show.name)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            LogoView()
        }
    }

    private var metadata: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Parameters.metaSpacing) {
                if !firstAirYear.isEmpty {
                    metadataChip(firstAirYear)
                }

                if let status = show.status, !status.isEmpty {
                    metadataChip(status)
                }

                if let runtime = show.episodeRunTime.first {
                    metadataChip("\(runtime) min")
                }

                if show.numberOfSeasons > 0 {
                    metadataChip("\(show.numberOfSeasons) seasons")
                }

                ForEach(show.genres.prefix(3)) { genre in
                    metadataChip(genre.name)
                }
            }
        }
        .padding(.top, Parameters.metaTopPadding)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: Parameters.baseSpacing) {
            Text(show.overview.isEmpty ? "No overview available." : show.overview)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.overviewFontSize))
                .lineLimit(expanded ? nil : Parameters.lineLimitCollapsed)
                .animation(.default, value: expanded)

            if !show.overview.isEmpty {
                Button {
                    expanded.toggle()
                } label: {
                    HStack {
                        Text(expanded ? "See less" : "See more")
                        Image(systemName: "chevron.down")
                            .rotationEffect(expanded ? .degrees(180) : .zero)
                    }
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.metaFontSize))
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    @ViewBuilder
    private var trailerSection: some View {
        if let trailer = show.trailer {
            VStack(alignment: .leading, spacing: Parameters.sectionContentSpacing) {
                SectionTitleView(title: "Trailer")
                MovieTrailerView(trailer: trailer) {
                    if let url = trailer.youtubeWatchURL {
                        openURL(url)
                    }
                }
            }
            .padding(.top, Parameters.largeSectionSpacing)
        }
    }

    @ViewBuilder
    private var castSection: some View {
        if !show.cast.isEmpty {
            VStack(alignment: .leading, spacing: Parameters.sectionContentSpacing) {
                SectionTitleView(
                    title: "Cast",
                    destination: MovieCastListView(cast: show.cast)
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.peopleSpacing) {
                        ForEach(show.cast.prefix(Parameters.previewPersonCount)) { actor in
                            NavigationLink {
                                CrewPersonDetailView(
                                    personID: actor.id,
                                    name: actor.name,
                                    role: nil,
                                    profilePath: actor.profilePath
                                )
                            } label: {
                                PersonChipView(
                                    name: actor.name,
                                    role: nil,
                                    profilePath: actor.profilePath,
                                    nameLineLimit: 2
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, Parameters.largeSectionSpacing)
        }
    }

    @ViewBuilder
    private var crewSection: some View {
        let crew = filteredCrew
        if !crew.isEmpty {
            VStack(alignment: .leading, spacing: Parameters.sectionContentSpacing) {
                SectionTitleView(
                    title: "Crew",
                    destination: MovieCrewListView(crew: show.crew)
                )
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.peopleSpacing) {
                        ForEach(crew.prefix(Parameters.previewPersonCount), id: \.id) { member in
                            NavigationLink {
                                CrewPersonDetailView(
                                    personID: member.id,
                                    name: member.name,
                                    role: member.job,
                                    profilePath: member.profilePath
                                )
                            } label: {
                                PersonChipView(
                                    name: member.name,
                                    role: member.job,
                                    profilePath: member.profilePath,
                                    nameLineLimit: 1
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, Parameters.largeSectionSpacing)
        }
    }

    private var filteredCrew: [MovieCrew] {
        let essentialJobs = ["Executive Producer", "Showrunner", "Director", "Producer", "Writer", "Screenplay"]
        return show.crew.filter { member in
            member.job.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .contains { essentialJobs.contains($0) }
        }
    }

    @ViewBuilder
    private var gallerySection: some View {
        let images = show.galleryImages
        if !images.isEmpty {
            VStack(alignment: .leading, spacing: Parameters.sectionContentSpacing) {
                SectionTitleView(
                    title: "Gallery",
                    destination: MovieGalleryListView(title: "Gallery", images: images)
                )
                MovieImageGalleryView(images: Array(images.prefix(Parameters.galleryPreviewCount)))
            }
            .padding(.top, Parameters.largeSectionSpacing)
        }
    }

    @ViewBuilder
    private var seasonsSection: some View {
        let seasons = show.seasons.filter { $0.episodeCount > 0 }
        if !seasons.isEmpty {
            VStack(alignment: .leading, spacing: Parameters.sectionContentSpacing) {
                SectionTitleView(title: "Seasons")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.seasonSpacing) {
                        ForEach(seasons) { season in
                            NavigationLink {
                                if case let .authenticated(userID) = userSession.authState {
                                    TVEpisodesView(
                                        showID: show.id,
                                        showName: show.name,
                                        posterPath: show.posterPath,
                                        seasons: show.seasons,
                                        userID: userID
                                    )
                                } else {
                                    TVShowSeasonSummaryView(showName: show.name, season: season)
                                }
                            } label: {
                                TVSeasonCardView(season: season)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, Parameters.largeSectionSpacing)
        }
    }

    private var tvShowInfoSection: some View {
        VStack(alignment: .leading, spacing: Parameters.sectionContentSpacing) {
            SectionTitleView(title: "TV Show Info")

            VStack(alignment: .leading, spacing: 12) {
                if !show.createdBy.isEmpty {
                    infoRow(title: "Created by", value: show.createdBy.map(\.name).joined(separator: ", "))
                }
                if !show.networks.isEmpty {
                    infoRow(title: "Network", value: show.networks.map(\.name).joined(separator: ", "))
                }
                if let type = show.type, !type.isEmpty {
                    infoRow(title: "Type", value: type)
                }
                if !show.firstAirDate.isEmpty {
                    infoRow(title: "On air", value: onAirText)
                }
                infoRow(title: "Episodes", value: "\(show.numberOfEpisodes)")
                if !show.originCountry.isEmpty {
                    infoRow(title: "Origin", value: show.originCountry.joined(separator: ", "))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(AppUI.Radius.card)
        }
        .padding(.top, Parameters.largeSectionSpacing)
    }

    private var onAirText: String {
        let start = formatDate(show.firstAirDate)
        let isEnded = show.status == "Ended" || show.status == "Canceled" || show.status == "Cancelled"
        if isEnded, let last = show.lastAirDate, !last.isEmpty {
            return "\(start) – \(formatDate(last))"
        }
        return "\(start) – present"
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

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Font.custom(AppUI.FontName.poppins, size: 14))
                .foregroundStyle(Color(white: 0.32))
            Text(value.isEmpty ? "—" : value)
                .font(Font.custom(AppUI.FontName.poppins, size: 14))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func formatDate(_ input: String) -> String {
        if let date = Self.apiDateFormatter.date(from: input) {
            return Self.displayDateFormatter.string(from: date)
        }
        return input
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    private func refreshProgress() {
        guard case let .authenticated(userID) = userSession.authState else {
            watchedCount = 0
            return
        }
        watchedCount = progressService.watchedEpisodeIDs(userID: userID, showID: show.id).count
        syncSeenStatusIfCompleted(userID: userID)
    }

    private func syncSeenStatusIfCompleted(userID: String) {
        let totalEpisodeCount = show.seasons
            .filter { $0.seasonNumber > 0 }
            .reduce(0) { $0 + $1.episodeCount }
        guard totalEpisodeCount > 0, watchedCount >= totalEpisodeCount else { return }

        TVShowLibraryService().set(
            .seen,
            isSet: true,
            showID: show.id,
            userID: userID,
            title: show.name,
            posterPath: show.posterPath
        )
    }

    private var firstAirYear: String {
        String(show.firstAirDate.prefix(4))
    }

    private let progressService = TVEpisodeProgressService()

    private enum Parameters {
        static let titleFontSize: CGFloat = 20
        static let taglineFontSize: CGFloat = 15
        static let metaFontSize: CGFloat = 14
        static let overviewFontSize: CGFloat = 16
        static let chipFontSize: CGFloat = 12
        static let taglineTopPadding: CGFloat = 10
        static let metaTopPadding: CGFloat = 4
        static let overviewTopPadding: CGFloat = 18
        static let largeSectionSpacing: CGFloat = 24
        static let sectionContentSpacing: CGFloat = 4
        static let baseSpacing: CGFloat = 4
        static let metaSpacing: CGFloat = 8
        static let peopleSpacing: CGFloat = 10
        static let seasonSpacing: CGFloat = 12
        static let infoRowSpacing: CGFloat = 12
        static let chipHorizontalPadding: CGFloat = 10
        static let chipVerticalPadding: CGFloat = 6
        static let previewPersonCount = 10
        static let galleryPreviewCount = 15
        static let lineLimitCollapsed = 3
    }
}

private struct TVShowEpisodeProgressCard: View {
    let show: RemoteTVShowDetail
    let userID: String
    let watchedCount: Int

    var body: some View {
        let total = max(show.numberOfEpisodes, 1)
        let progress = min(Double(watchedCount) / Double(total), 1)

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Episode Progress")
                        .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 18))
                    Text("\(watchedCount) of \(show.numberOfEpisodes) episodes watched")
                        .font(Font.custom(AppUI.FontName.poppins, size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 16))
            }

            ProgressView(value: progress)
                .tint(AppUI.ColorPalette.accent)

            NavigationLink {
                TVEpisodesView(
                    showID: show.id,
                    showName: show.name,
                    posterPath: show.posterPath,
                    seasons: show.seasons,
                    userID: userID
                )
            } label: {
                Label(watchedCount == 0 ? "Start tracking episodes" : "Continue tracking", systemImage: "list.bullet.rectangle")
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 14))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppUI.ColorPalette.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppUI.ColorPalette.secondarySurface)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
    }
}

#Preview {
    NavigationStack {
        TVShowDetailLoaderView(showID: 1399)
            .environmentObject(UserSession())
    }
}
