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
                    "No Titles",
                    systemImage: "rectangle.stack",
                    description: Text("Movies and TV shows you add will appear here.")
                )
            } else {
                List(items) { item in
                    NavigationLink {
                        destination(for: item)
                    } label: {
                        HStack(spacing: 14) {
                            poster(for: item)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 17))
                                    .lineLimit(2)

                                Text(mediaType(for: item))
                                    .font(Font.custom(AppUI.FontName.poppins, size: 12))
                                    .foregroundStyle(.secondary)

                                if item.date != .distantPast {
                                    Text(item.date, style: .date)
                                        .font(Font.custom(AppUI.FontName.poppins, size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
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
        case .movie: "Movie"
        case .tvShow: "TV Show"
        }
    }

    private func poster(for item: ProfileLibraryMediaItem) -> some View {
        Group {
            if let path = item.posterPath,
               let url = URL(string: "https://image.tmdb.org/t/p/w342\(path)") {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: 72, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .clipped()
    }

    private var placeholder: some View {
        PosterPlaceholderView(cornerRadius: 12, iconSize: 20)
    }
}
