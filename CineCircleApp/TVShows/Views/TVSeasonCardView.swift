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
        static let posterWidth: CGFloat = 100
        static let posterHeight: CGFloat = 150
        static let posterCornerRadius: CGFloat = 12
        static let placeholderIconSize: CGFloat = 20
        static let textSpacing: CGFloat = 4
        static let titleFontSize: CGFloat = 12
        static let subtitleFontSize: CGFloat = 10
        static let cardHeight: CGFloat = 210
    }
}

/// Shown when a user taps a season card but is not signed in — prompts them to log in to track episodes.
struct TVShowSeasonSummaryView: View {
    let showName: String
    let season: RemoteTVSeasonSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(showName)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 22))
            TVSeasonCardView(season: season)
            Text("Sign in to track episodes.")
                .font(Font.custom(AppUI.FontName.poppins, size: 14))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle(season.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
