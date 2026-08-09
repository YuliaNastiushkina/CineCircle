import SwiftUI

struct MovieListRow: View {
    let movie: RemoteMovie

    @State private var movieDetail: RemoteMovieDetail?

    private let apiClient = APIClient()

    var body: some View {
        MediaListRow(
            title: movie.title,
            posterPath: movie.posterPath,
            primaryMetadata: releaseYear,
            secondaryMetadata: runtimeText,
            language: languageText,
            genres: genreLine,
            rating: movie.voteAverage,
            ratingCount: ratingCount
        )
        .task {
            await loadMovieDetailIfNeeded()
        }
    }

    private var releaseYear: String {
        let year = String(movie.releaseDate.prefix(Parameters.releaseYearCharacterCount))
        return year.isEmpty ? "TBA" : year
    }

    private var runtimeText: String? {
        guard let movieDetail else { return nil }
        let text = MovieFormatter.runtimeText(minutes: movieDetail.runtime)
        return text == "—" ? nil : text
    }

    private var languageText: String {
        let language = movieDetail?.originalLanguage ?? movie.originalLanguage
        return language.uppercased()
    }

    private var genreTexts: [String] {
        if let movieDetail, !movieDetail.genres.isEmpty {
            return Array(movieDetail.genres.map(\.name).prefix(MoviesListLayout.maximumGenreCount))
        }

        return movie.genreIDs
            .compactMap { MoviesGenre.genre(forTMDBID: $0)?.displayName }
            .prefix(MoviesListLayout.maximumGenreCount)
            .map { $0 }
    }

    private var genreLine: String {
        genreTexts.joined(separator: Parameters.genreSeparator)
    }

    private var ratingCount: Int {
        movieDetail?.voteCount ?? movie.voteCount
    }

    private func loadMovieDetailIfNeeded() async {
        guard movieDetail == nil else { return }

        do {
            movieDetail = try await apiClient.fetch(
                path: "movie/\(movie.id)",
                query: [:],
                responseType: RemoteMovieDetail.self
            )
        } catch {
            // Keep the row usable with the basic list data if detail loading fails.
        }
    }

    private enum Parameters {
        static let releaseYearCharacterCount = 4
        static let genreSeparator = ", "
    }
}
