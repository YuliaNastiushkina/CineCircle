import SwiftUI

struct RecentActivityView: View {
    let recentActivity: RecentActivity

    var body: some View {
        VStack(spacing: Parameters.sectionGroupSpacing) {
            // Recently Watched Movies
            if !recentActivity.recentlyWatched.isEmpty {
                VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
                    sectionHeader(
                        title: "Recently Watched",
                        actionTitle: "View All",
                        actionColor: .blue
                    ) {
                        print("Navigate to recently watched")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Parameters.horizontalListSpacing) {
                            ForEach(recentActivity.recentlyWatched, id: \.id) { movie in
                                RecentMovieCard(movie: movie)
                            }
                        }
                        .padding(.horizontal, Parameters.horizontalListPadding)
                    }
                }
            }

            // Watchlist Quick Access
            if !recentActivity.watchlistItems.isEmpty {
                VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
                    sectionHeader(
                        title: "Watchlist",
                        actionTitle: "View All",
                        actionColor: .blue
                    ) {
                        print("Navigate to watchlist")
                    }

                    VStack(spacing: Parameters.watchlistSpacing) {
                        ForEach(Array(recentActivity.watchlistItems.prefix(3)), id: \.id) { movie in
                            WatchlistItemRow(movie: movie)
                        }
                    }
                }
            }

            // Custom Lists
            if !recentActivity.customLists.isEmpty {
                VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
                    sectionHeader(
                        title: "My Lists",
                        actionTitle: "Create New",
                        actionColor: .green
                    ) {}

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: Parameters.gridSpacing) {
                        ForEach(recentActivity.customLists, id: \.id) { list in
                            CustomListCard(list: list)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func sectionHeader(
        title: String,
        actionTitle: String,
        actionColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.sectionTitleFontSize))
                .foregroundColor(.primary)
            Spacer()
            Button(actionTitle, action: action)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.sectionActionFontSize))
                .foregroundColor(actionColor)
        }
    }

    private enum Parameters {
        static let sectionGroupSpacing: CGFloat = 20
        static let sectionSpacing: CGFloat = 12
        static let sectionTitleFontSize: CGFloat = 16
        static let sectionActionFontSize: CGFloat = 12
        static let horizontalListSpacing: CGFloat = 12
        static let horizontalListPadding: CGFloat = 4
        static let watchlistSpacing: CGFloat = 8
        static let gridSpacing: CGFloat = 12
    }
}

struct RecentMovieCard: View {
    let movie: RecentMovie

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.containerSpacing) {
            // Movie poster placeholder
            PosterPlaceholderView(
                cornerRadius: Parameters.posterCornerRadius,
                iconSize: Parameters.placeholderIconSize
            )
            .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)

            VStack(alignment: .leading, spacing: Parameters.textSpacing) {
                Text(movie.title)
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(width: Parameters.posterWidth, alignment: .leading)

                if let rating = movie.rating {
                    HStack(spacing: Parameters.ratingSpacing) {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppUI.ColorPalette.accent)
                            .font(.system(size: Parameters.ratingIconSize))
                        Text(String(format: "%.1f", rating))
                            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.ratingFontSize))
                            .foregroundColor(.secondary)
                    }
                }

                Text(formatDate(movie.watchedDate))
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.dateFontSize))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: Parameters.posterWidth)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private enum Parameters {
        static let containerSpacing: CGFloat = 8
        static let posterCornerRadius: CGFloat = 8
        static let placeholderIconSize: CGFloat = 24
        static let posterWidth: CGFloat = 100
        static let posterHeight: CGFloat = 150
        static let textSpacing: CGFloat = 2
        static let titleFontSize: CGFloat = 12
        static let ratingSpacing: CGFloat = 2
        static let ratingIconSize: CGFloat = 10
        static let ratingFontSize: CGFloat = 10
        static let dateFontSize: CGFloat = 9
    }
}

struct WatchlistItemRow: View {
    let movie: WatchlistMovie

    var body: some View {
        HStack(spacing: Parameters.rowSpacing) {
            PosterPlaceholderView(
                cornerRadius: Parameters.posterCornerRadius,
                iconSize: Parameters.placeholderIconSize
            )
            .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)

            VStack(alignment: .leading, spacing: Parameters.textSpacing) {
                Text(movie.title)
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("Added \(formatDate(movie.addedDate))")
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Priority indicator
            Circle()
                .fill(priorityColor(movie.priority))
                .frame(width: Parameters.priorityIndicatorSize, height: Parameters.priorityIndicatorSize)
        }
        .padding(.horizontal, Parameters.horizontalPadding)
        .padding(.vertical, Parameters.verticalPadding)
        .background(AppUI.ColorPalette.secondarySurface)
        .cornerRadius(Parameters.cardCornerRadius)
    }

    private func priorityColor(_ priority: WatchlistPriority) -> Color {
        switch priority {
        case .high: .red
        case .medium: .orange
        case .low: .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private enum Parameters {
        static let rowSpacing: CGFloat = 12
        static let posterCornerRadius: CGFloat = 6
        static let placeholderIconSize: CGFloat = 12
        static let posterWidth: CGFloat = 40
        static let posterHeight: CGFloat = 60
        static let textSpacing: CGFloat = 4
        static let titleFontSize: CGFloat = 14
        static let subtitleFontSize: CGFloat = 11
        static let priorityIndicatorSize: CGFloat = 8
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let cardCornerRadius: CGFloat = 8
    }
}

struct CustomListCard: View {
    let list: ProfileCustomList

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            HStack {
                Image(systemName: list.icon)
                    .foregroundColor(.blue)
                    .font(.system(size: Parameters.iconSize))
                Spacer()
                Text("\(list.movieCount)")
                    .font(Font.custom(AppUI.FontName.poppinsBold, size: Parameters.countFontSize))
                    .foregroundColor(.primary)
            }

            Text(list.name)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .foregroundColor(.primary)
                .lineLimit(1)

            Text("movies")
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                .foregroundColor(.secondary)
        }
        .padding(Parameters.cardPadding)
        .background(AppUI.ColorPalette.secondarySurface)
        .cornerRadius(Parameters.cornerRadius)
        .shadow(color: .black.opacity(Parameters.shadowOpacity), radius: Parameters.shadowRadius, x: 0, y: Parameters.shadowYOffset)
    }

    private enum Parameters {
        static let contentSpacing: CGFloat = 8
        static let iconSize: CGFloat = 16
        static let countFontSize: CGFloat = 16
        static let titleFontSize: CGFloat = 14
        static let subtitleFontSize: CGFloat = 10
        static let cardPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 10
        static let shadowOpacity: Double = 0.05
        static let shadowRadius: CGFloat = 2
        static let shadowYOffset: CGFloat = 1
    }
}

#Preview {
    RecentActivityView(recentActivity: RecentActivity(
        recentlyWatched: [
            RecentMovie(id: "1", title: "Dune: Part Two", posterURL: nil, rating: 4.8, watchedDate: Date().addingTimeInterval(-86400), genre: "Sci-Fi"),
        ],
        watchlistItems: [
            WatchlistMovie(id: "1", title: "The Batman", posterURL: nil, addedDate: Date().addingTimeInterval(-86400), priority: .high),
        ],
        customLists: [
            ProfileCustomList(id: "1", movieCount: 10, name: "My Top 10", icon: "star.fill", createdDate: Date()),
        ]
    ))
    .padding()
}
