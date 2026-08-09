import SwiftUI

struct ProfileNotePreviewCard: View {
    let item: ProfileNoteItem

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            Text(item.title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            LazyVGrid(columns: Parameters.metadataColumns, alignment: .leading, spacing: Parameters.metaSpacing) {
                ForEach(Array(item.moods.prefix(Parameters.previewMoodCount)), id: \.self) { mood in
                    metadataChip(mood.title)
                }

                metadataChip(item.watchType.title)
                metadataChip("With: \(item.watchedWith.title)")

                if item.hasSpoilers {
                    metadataChip("Spoilers")
                }
            }

            if !item.content.isEmpty {
                Text(item.content)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if let date = item.watchedDate ?? item.createdAt {
                Text(date, style: .date)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.dateFontSize))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: Parameters.cardWidth, height: Parameters.cardHeight, alignment: .topLeading)
        .padding(Parameters.cardPadding)
        .background(AppUI.ColorPalette.softCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
    }

    private func metadataChip(_ title: String) -> some View {
        Text(title)
            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.chipFontSize))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Parameters.chipHorizontalPadding)
            .padding(.vertical, Parameters.chipVerticalPadding)
            .background(Color(.systemBackground))
            .clipShape(Capsule())
    }

    private enum Parameters {
        static let cardWidth: CGFloat = 240
        static let cardHeight: CGFloat = 160
        static let cardPadding: CGFloat = 14
        static let contentSpacing = AppUI.Spacing.small
        static let metaSpacing: CGFloat = 6
        static let titleFontSize = AppUI.FontSize.body
        static let subtitleFontSize: CGFloat = 11
        static let bodyFontSize = AppUI.FontSize.caption
        static let dateFontSize: CGFloat = 11
        static let chipFontSize: CGFloat = 10
        static let previewMoodCount = 2
        static let chipHorizontalPadding: CGFloat = 7
        static let chipVerticalPadding: CGFloat = 3
        static let metadataColumns = [GridItem(.adaptive(minimum: 88), spacing: metaSpacing)]
    }
}
