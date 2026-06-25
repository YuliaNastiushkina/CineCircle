import SwiftUI

struct ProfileMediaListView: View {
    let title: String
    let movies: [ProfileMovieSnapshot]
    let tvShows: [TVShowLibraryRecord]

    private var items: [ProfileLibraryMediaItem] {
        (movies.map(ProfileLibraryMediaItem.movie) + tvShows.map(ProfileLibraryMediaItem.tvShow))
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    Parameters.emptyTitle,
                    systemImage: "rectangle.stack",
                    description: Text(Parameters.emptyMessage)
                )
            } else {
                List(items) { item in
                    NavigationLink {
                        destination(for: item)
                    } label: {
                        HStack(spacing: Parameters.rowSpacing) {
                            poster(for: item)

                            VStack(alignment: .leading, spacing: Parameters.textSpacing) {
                                Text(item.title)
                                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                                    .lineLimit(2)

                                Text(mediaType(for: item))
                                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                                    .foregroundStyle(.secondary)

                                if item.date != .distantPast {
                                    Text(item.date, style: .date)
                                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, Parameters.rowVerticalPadding)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
    }

    @ViewBuilder private func destination(for item: ProfileLibraryMediaItem) -> some View {
        switch item {
        case let .movie(movie):
            MovieDetailViewLoaderView(movieID: movie.id)
        case let .tvShow(show):
            TVShowDetailLoaderView(showID: show.id)
        }
    }

    private func mediaType(for item: ProfileLibraryMediaItem) -> String {
        switch item {
        case .movie: Parameters.movieLabel
        case .tvShow: Parameters.tvShowLabel
        }
    }

    private func poster(for item: ProfileLibraryMediaItem) -> some View {
        Group {
            if let path = item.posterPath,
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
        static let emptyTitle = "No Titles"
        static let emptyMessage = "Movies and TV shows you add will appear here."
        static let movieLabel = "Movie"
        static let tvShowLabel = "TV Show"
        static let rowSpacing: CGFloat = 14
        static let textSpacing: CGFloat = 6
        static let rowVerticalPadding = AppUI.Spacing.xxSmall
        static let titleFontSize = AppUI.FontSize.subheadline
        static let subtitleFontSize = AppUI.FontSize.caption
        static let posterWidth = AppUI.PosterSize.compactWidth
        static let posterHeight = AppUI.PosterSize.compactHeight
        static let posterCornerRadius = AppUI.PosterSize.cornerRadius
        static let placeholderIconSize = AppUI.PosterSize.placeholderIconSize
    }
}
