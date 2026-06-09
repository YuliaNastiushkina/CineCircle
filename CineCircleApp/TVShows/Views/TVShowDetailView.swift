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

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(show.name)
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 20))
                Spacer()
                LogoView()
            }

            metadata

            VStack(alignment: .leading, spacing: 4) {
                Text(show.overview.isEmpty ? "No overview available." : show.overview)
                    .font(Font.custom(AppUI.FontName.poppins, size: 16))
                    .lineLimit(expanded ? nil : 3)

                if !show.overview.isEmpty {
                    Button {
                        expanded.toggle()
                    } label: {
                        HStack {
                            Text(expanded ? "See less" : "See more")
                            Image(systemName: "chevron.down")
                                .rotationEffect(expanded ? .degrees(180) : .zero)
                        }
                        .font(Font.custom(AppUI.FontName.poppins, size: 14))
                        .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 12) {
                SectionTitleView(title: "TV Show Info")
                infoRow(title: "First aired", value: show.firstAirDate)
                if let lastAirDate = show.lastAirDate, !lastAirDate.isEmpty {
                    infoRow(title: "Last aired", value: lastAirDate)
                }
                infoRow(title: "Seasons", value: "\(show.numberOfSeasons)")
                infoRow(title: "Episodes", value: "\(show.numberOfEpisodes)")
                if let runtime = show.episodeRunTime.first {
                    infoRow(title: "Episode runtime", value: "\(runtime) min")
                }
            }
            .padding(.top, 32)
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }

    private var metadata: some View {
        HStack(spacing: 4) {
            Text(String(show.firstAirDate.prefix(4)))
            dot
            Text(show.genres.map(\.name).joined(separator: ", "))
                .lineLimit(1)
            if let runtime = show.episodeRunTime.first {
                dot
                Text("\(runtime) min")
            }
        }
        .font(Font.custom(AppUI.FontName.poppins, size: 14))
        .foregroundStyle(.secondary)
    }

    private var dot: some View {
        Circle()
            .fill(AppUI.ColorPalette.accent)
            .frame(width: 4, height: 4)
            .padding(5)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(Font.custom(AppUI.FontName.poppins, size: 14))
    }
}

#Preview {
    NavigationStack {
        TVShowDetailLoaderView(showID: 1399)
            .environmentObject(UserSession())
    }
}
