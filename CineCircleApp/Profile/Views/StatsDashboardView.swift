import SwiftUI

struct StatsDashboardView: View {
    let stats: MovieStats
    let userId: String
    let watchedMovieIDs: [Int]
    let savedMovieIDs: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
            Text("Your Activity")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .foregroundColor(.primary)

            if stats.totalWatched == 0, stats.totalSaved == 0, stats.totalNotes == 0 {
                emptyStateView
            } else {
                statsGrid
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: Parameters.gridSpacing) {
            if stats.totalWatched > 0 {
                NavigationLink {
                    ProfileMovieListView(title: "Watched", movieIDs: watchedMovieIDs)
                } label: {
                    StatCard(title: "Watched", value: "\(stats.totalWatched)", icon: "eye.fill", iconColor: .blue)
                }
                .buttonStyle(.plain)
            } else {
                StatCard(title: "Watched", value: "0", icon: "eye.fill", iconColor: .blue)
            }

            if stats.totalSaved > 0 {
                NavigationLink {
                    ProfileMovieListView(title: "Watchlist", movieIDs: savedMovieIDs)
                } label: {
                    StatCard(title: "Watchlist", value: "\(stats.totalSaved)", icon: "bookmark.fill", iconColor: .orange)
                }
                .buttonStyle(.plain)
            } else {
                StatCard(title: "Watchlist", value: "0", icon: "bookmark.fill", iconColor: .orange)
            }

            if stats.totalNotes > 0 {
                NavigationLink {
                    ProfileNotesListView(userId: userId)
                } label: {
                    StatCard(title: "Diary", value: "\(stats.totalNotes)", icon: "book.closed", iconColor: .purple)
                }
                .buttonStyle(.plain)
            } else {
                StatCard(title: "Diary", value: "0", icon: "book.closed", iconColor: .purple)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Parameters.emptyStateSpacing) {
            Image(systemName: "film.stack")
                .font(.system(size: Parameters.emptyStateIconSize))
                .foregroundColor(.secondary.opacity(Parameters.emptyStateIconOpacity))

            Text("No activity yet")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.emptyStateTitleSize))
                .foregroundColor(.secondary)

            Text("Start exploring movies to see your stats here")
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.emptyStateBodySize))
                .foregroundColor(.secondary.opacity(Parameters.emptyStateBodyOpacity))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Parameters.emptyStateVerticalPadding)
        .background(AppUI.ColorPalette.softCardBackground)
        .cornerRadius(AppUI.Radius.card)
    }

    private enum Parameters {
        static let sectionSpacing: CGFloat = 12
        static let titleFontSize: CGFloat = 16
        static let gridSpacing: CGFloat = 10
        static let emptyStateSpacing: CGFloat = 8
        static let emptyStateIconSize: CGFloat = 24
        static let emptyStateIconOpacity: Double = 0.6
        static let emptyStateTitleSize: CGFloat = 14
        static let emptyStateBodySize: CGFloat = 12
        static let emptyStateBodyOpacity: Double = 0.8
        static let emptyStateVerticalPadding: CGFloat = 24
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: Parameters.contentSpacing) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: Parameters.iconSize, weight: .medium))

            Text(value)
                .font(Font.custom(AppUI.FontName.poppinsBold, size: Parameters.valueFontSize))
                .foregroundColor(.primary)

            Text(title)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.titleFontSize))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Parameters.verticalPadding)
        .background(AppUI.ColorPalette.softCardBackground)
        .cornerRadius(AppUI.Radius.card)
    }

    private enum Parameters {
        static let contentSpacing: CGFloat = 6
        static let iconSize: CGFloat = 18
        static let valueFontSize: CGFloat = 22
        static let titleFontSize: CGFloat = 12
        static let verticalPadding: CGFloat = 16
    }
}

#Preview("With Stats") {
    NavigationStack {
        StatsDashboardView(
            stats: MovieStats(totalWatched: 12, totalSaved: 5, totalNotes: 3),
            userId: "preview",
            watchedMovieIDs: [550, 680],
            savedMovieIDs: [550]
        )
        .padding()
    }
}

#Preview("Empty") {
    StatsDashboardView(
        stats: MovieStats(),
        userId: "preview",
        watchedMovieIDs: [],
        savedMovieIDs: []
    )
    .padding()
}
