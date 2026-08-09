import SwiftUI

struct ProfileMediaPosterCard: View {
    let item: ProfileLibraryMediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.textSpacing) {
            poster
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

    @ViewBuilder
    private var poster: some View {
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
