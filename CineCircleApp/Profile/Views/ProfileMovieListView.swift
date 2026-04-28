import SwiftUI

/// Displays a list of movies fetched by their IDs from the TMDB API.
/// Used from the profile to show watched or saved movies.
struct ProfileMovieListView: View {
    let title: String
    let movieIDs: [Int]

    @State private var movies: [RemoteMovieDetail] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let apiClient = APIClient()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading movies...")
            } else if movies.isEmpty {
                ContentUnavailableView(
                    "No Movies",
                    systemImage: "film.stack",
                    description: Text("Movies you add will appear here.")
                )
            } else {
                List(movies) { movie in
                    NavigationLink {
                        MovieDetailViewLoaderView(movieID: movie.id)
                    } label: {
                        MovieRow(movie: movie)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadMovies()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadMovies() async {
        isLoading = true
        var loaded: [RemoteMovieDetail] = []
        for id in movieIDs {
            do {
                let detail = try await apiClient.fetch(
                    path: "movie/\(id)",
                    query: [:],
                    responseType: RemoteMovieDetail.self
                )
                loaded.append(detail)
            } catch {
                // Skip movies that fail to load (e.g. deleted from TMDB)
                continue
            }
        }
        movies = loaded
        isLoading = false
    }
}

// MARK: - Movie Row

private struct MovieRow: View {
    let movie: RemoteMovieDetail

    var body: some View {
        HStack(alignment: .top, spacing: Parameters.rowSpacing) {
            posterImage
            movieInfo
        }
        .padding(.vertical, Parameters.rowVerticalPadding)
    }

    private var posterImage: some View {
        Group {
            if let path = movie.posterPath {
                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w342\(path)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    posterPlaceholder
                }
            } else {
                posterPlaceholder
            }
        }
        .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: Parameters.posterCornerRadius))
        .clipped()
    }

    private var posterPlaceholder: some View {
        PosterPlaceholderView(
            cornerRadius: Parameters.posterCornerRadius,
            iconSize: Parameters.placeholderIconSize
        )
    }

    private var movieInfo: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            Text(movie.title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                .foregroundColor(.primary)
                .lineLimit(2)

            HStack(spacing: Parameters.metadataSpacing) {
                metadataChip(text: releaseYear)

                if let runtimeText {
                    metadataChip(text: runtimeText)
                }

                if !languageText.isEmpty {
                    metadataChip(text: languageText)
                }
            }

            if !genreLine.isEmpty {
                metadataChip(text: genreLine)
            }

            HStack(spacing: Parameters.ratingSpacing) {
                Text(String(format: "%.1f", movie.voteAverage))
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.ratingFontSize))
                    .foregroundColor(.primary)

                Image(systemName: "star.fill")
                    .foregroundColor(AppUI.ColorPalette.accent)
                    .font(.system(size: Parameters.starIconSize))

                Text("(\(ratingCount))")
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.ratingFontSize))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var releaseYear: String {
        let year = String(movie.releaseDate.prefix(4))
        return year.isEmpty ? "TBA" : year
    }

    private var runtimeText: String? {
        let text = MovieFormatter.runtimeText(minutes: movie.runtime)
        return text == "—" ? nil : text
    }

    private var languageText: String {
        movie.originalLanguage.uppercased()
    }

    private var genreLine: String {
        movie.genres
            .map(\.name)
            .prefix(3)
            .joined(separator: ", ")
    }

    private var ratingCount: Int {
        movie.voteCount
    }

    @ViewBuilder private func metadataChip(text: String) -> some View {
        MetadataChip(
            text: text,
            font: Font.custom(AppUI.FontName.poppins, size: Parameters.metadataFontSize)
        )
    }

    private enum Parameters {
        static let rowSpacing: CGFloat = 16
        static let rowVerticalPadding: CGFloat = 2
        static let posterWidth: CGFloat = 96
        static let posterHeight: CGFloat = 144
        static let posterCornerRadius: CGFloat = AppUI.Radius.medium
        static let placeholderIconSize: CGFloat = 24
        static let contentSpacing: CGFloat = 10
        static let titleFontSize: CGFloat = 20
        static let metadataSpacing: CGFloat = 8
        static let metadataFontSize: CGFloat = 13
        static let ratingSpacing: CGFloat = 6
        static let ratingFontSize: CGFloat = 16
        static let starIconSize: CGFloat = 14
    }
}

#Preview {
    NavigationStack {
        ProfileMovieListView(title: "Watched", movieIDs: [550, 680])
    }
}
