import SwiftUI

struct MediaListRow: View {
    let title: String
    let posterPath: String?
    let primaryMetadata: String
    let secondaryMetadata: String?
    let language: String
    let genres: String
    let rating: Double
    let ratingCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: Parameters.rowSpacing) {
            posterImage

            VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
                Text(title)
                    .font(Font.custom(AppUI.FontName.poppinsLight, size: Parameters.titleFontSize))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .padding(.bottom, Parameters.titleBottomPadding)

                HStack(spacing: Parameters.metadataSpacing) {
                    metadataChip(primaryMetadata)
                    if let secondaryMetadata, !secondaryMetadata.isEmpty {
                        metadataChip(secondaryMetadata)
                    }
                    if !language.isEmpty {
                        metadataChip(language.uppercased())
                    }
                }

                if !genres.isEmpty {
                    metadataChip(genres)
                }

                Spacer()

                HStack(spacing: Parameters.ratingSpacing) {
                    Text(String(format: "%.1f", rating))
                        .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.ratingFontSize))
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppUI.ColorPalette.accent)
                        .font(.system(size: Parameters.ratingFontSize))
                    Text("(\(ratingCount))")
                        .font(Font.custom(AppUI.FontName.poppinsLight, size: Parameters.ratingFontSize))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Parameters.rowVerticalPadding)
    }

    private var posterImage: some View {
        Group {
            if let posterPath,
               let url = URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)") {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
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
        PosterPlaceholderView(
            cornerRadius: Parameters.posterCornerRadius,
            iconSize: Parameters.placeholderIconSize
        )
    }

    private func metadataChip(_ text: String) -> some View {
        MetadataChip(
            text: text,
            font: Font.custom(AppUI.FontName.poppinsLight, size: Parameters.metadataFontSize),
            horizontalPadding: Parameters.metadataHorizontalPadding,
            verticalPadding: Parameters.metadataVerticalPadding
        )
    }

    private enum Parameters {
        static let rowSpacing: CGFloat = 12
        static let rowVerticalPadding: CGFloat = 2
        static let posterWidth: CGFloat = 124
        static let posterHeight: CGFloat = 186
        static let posterCornerRadius: CGFloat = AppUI.Radius.medium
        static let placeholderIconSize: CGFloat = 24
        static let contentSpacing: CGFloat = 10
        static let titleFontSize: CGFloat = 20
        static let titleBottomPadding: CGFloat = 10
        static let metadataSpacing: CGFloat = 8
        static let metadataFontSize: CGFloat = 14
        static let metadataHorizontalPadding: CGFloat = 10
        static let metadataVerticalPadding: CGFloat = 4
        static let ratingSpacing: CGFloat = 6
        static let ratingFontSize: CGFloat = 14
    }
}
