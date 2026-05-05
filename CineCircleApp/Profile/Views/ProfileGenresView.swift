import SwiftUI

struct ProfileGenresView: View {
    let viewModel: ProfileViewModel
    let showGenrePicker: () -> Void

    var body: some View {
        Button(action: showGenrePicker) {
            VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
                HStack {
                    Text("Favorite Genres")
                        .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "pencil")
                        .font(.system(size: Parameters.pencilSize, weight: .bold))
                        .foregroundColor(.secondary)
                }

                if viewModel.favoriteGenres.isEmpty {
                    HStack(spacing: Parameters.emptyStateSpacing) {
                        Image(systemName: "tag")
                            .foregroundColor(.secondary.opacity(Parameters.emptyStateIconOpacity))
                        Text("No genres selected")
                            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.emptyStateFontSize))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, Parameters.emptyStateVerticalPadding)
                } else {
                    FlowLayout(spacing: Parameters.flowLayoutSpacing) {
                        ForEach(viewModel.favoriteGenres, id: \.self) { genre in
                            GenreChipView(genre: genre)
                        }
                    }
                }
            }
            .padding(Parameters.containerPadding)
            .background(AppUI.ColorPalette.softCardBackground)
            .cornerRadius(AppUI.Radius.card)
            .contentShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private enum Parameters {
        static let sectionSpacing: CGFloat = 12
        static let titleFontSize: CGFloat = 16
        static let pencilSize: CGFloat = 16
        static let emptyStateSpacing: CGFloat = 8
        static let emptyStateIconOpacity: Double = 0.6
        static let emptyStateFontSize: CGFloat = 14
        static let emptyStateVerticalPadding: CGFloat = 8
        static let flowLayoutSpacing: CGFloat = 8
        static let containerPadding: CGFloat = 16
    }
}

// MARK: - Genre Chip (yellow capsule with icon, matching app accent)

struct GenreChipView: View {
    let genre: MoviesGenre

    var body: some View {
        HStack(spacing: Parameters.contentSpacing) {
            Image(systemName: genre.icon)
                .font(.system(size: Parameters.iconSize, weight: .medium))
            Text(genre.displayName)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.fontSize))
        }
        .foregroundColor(.black)
        .padding(.horizontal, Parameters.horizontalPadding)
        .padding(.vertical, Parameters.verticalPadding)
        .background(
            Capsule()
                .fill(AppUI.ColorPalette.accent)
        )
    }

    private enum Parameters {
        static let contentSpacing: CGFloat = 5
        static let iconSize: CGFloat = 11
        static let fontSize: CGFloat = 13
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 8
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if index < rows.count - 1 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentRowWidth += size.width + spacing
        }
        return rows
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    ProfileGenresView(
        viewModel: ProfileViewModel(userId: "previewUser", authService: FirebaseAuthService()),
        showGenrePicker: {}
    )
    .padding()
}
