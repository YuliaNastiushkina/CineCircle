import SwiftUI

struct ProfileTrackedTVShowCard: View {
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

struct ProfileTrackedTVShowsListView: View {
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
                        ProfileTrackedTVShowRow(show: show)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Tracking")
    }
}

private struct ProfileTrackedTVShowRow: View {
    let show: ProfileTrackedTVShowItem

    var body: some View {
        HStack(spacing: Parameters.rowSpacing) {
            poster

            VStack(alignment: .leading, spacing: Parameters.textSpacing) {
                Text(show.title)
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                    .lineLimit(2)

                if let subtitle = show.subtitle {
                    Text(subtitle)
                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: show.progressValue)
                    .tint(AppUI.ColorPalette.accent)

                Text(show.progressText)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Parameters.rowVerticalPadding)
    }

    private var poster: some View {
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
        .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: Parameters.posterCornerRadius))
        .clipped()
    }

    private var placeholder: some View {
        PosterPlaceholderView(cornerRadius: Parameters.posterCornerRadius, iconSize: Parameters.placeholderIconSize)
    }

    private enum Parameters {
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
