import SwiftUI

/// A compact card displaying a single TV season's poster, name, and air year + episode count.
struct TVSeasonCardView: View {
    let season: RemoteTVSeasonSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.textSpacing) {
            poster

            Text(season.name)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.titleFontSize))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(width: Parameters.posterWidth, alignment: .topLeading)

            Text(subtitle)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: Parameters.posterWidth, alignment: .leading)
        }
        .frame(width: Parameters.posterWidth, height: Parameters.cardHeight, alignment: .topLeading)
    }

    @ViewBuilder
    private var poster: some View {
        if let posterPath = season.posterPath,
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
            .clipped()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        PosterPlaceholderView(cornerRadius: Parameters.posterCornerRadius, iconSize: Parameters.placeholderIconSize)
            .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
    }

    private var subtitle: String {
        let year = String((season.airDate ?? "").prefix(4))
        let episodeText = "\(season.episodeCount) episodes"
        return year.isEmpty ? episodeText : "\(year) · \(episodeText)"
    }

    private enum Parameters {
        static let posterWidth = AppUI.PosterSize.standardWidth
        static let posterHeight = AppUI.PosterSize.standardHeight
        static let posterCornerRadius = AppUI.PosterSize.cornerRadius
        static let placeholderIconSize = AppUI.PosterSize.placeholderIconSize
        static let textSpacing = AppUI.Spacing.xxSmall
        static let titleFontSize = AppUI.FontSize.caption
        static let subtitleFontSize: CGFloat = 10
        static let cardHeight: CGFloat = 210
    }
}

/// Shown when a user taps a season card but is not signed in — prompts them to log in to track episodes.
struct TVShowSeasonSummaryView: View {
    let showName: String
    let season: RemoteTVSeasonSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.spacing) {
            Text(showName)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
            TVSeasonCardView(season: season)
            Text(Parameters.signInPrompt)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle(season.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private enum Parameters {
        static let signInPrompt = "Sign in to track episodes."
        static let spacing = AppUI.Spacing.large
        static let titleFontSize = AppUI.FontSize.title2
        static let bodyFontSize = AppUI.FontSize.body
    }
}
