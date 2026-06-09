import SwiftUI

struct MoviePosterSectionView: View {
    let movie: RemoteMovieDetail
    let userSession: UserSession
    let onDismiss: () -> Void
    let onBookmark: () -> Void

    var body: some View {
        MediaPosterHeaderView(
            posterPath: movie.posterPath,
            rating: movie.voteAverage,
            onDismiss: onDismiss
        ) {
            if case let .authenticated(userID) = userSession.authState {
                BookmarkButton(
                    movieID: movie.id,
                    userID: userID,
                    movieTitle: movie.title,
                    posterPath: movie.posterPath
                )
            }
        } bottomTrailing: {
            if case let .authenticated(userID) = userSession.authState {
                WatchStatusButton(
                    movieID: movie.id,
                    userID: userID,
                    movieTitle: movie.title,
                    posterPath: movie.posterPath
                )
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color(white: 0.32).opacity(0.8))
                .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    let sampleMovie = RemoteMovieDetail(
        id: 675_353,
        title: "Sonic the Hedgehog 2",
        overview: "Sample overview",
        posterPath: "/6DrHO1jr3qVrViUO6s6kFiAGM7.jpg",
        backdropPath: nil,
        voteAverage: 7.5,
        voteCount: 1543,
        releaseDate: "2022-04-08",
        runtime: 121,
        originalLanguage: "EN",
        genres: [RemoteMovieDetail.Genre(id: 1, name: "Fiction")],
        productionCompanies: []
    )

    MoviePosterSectionView(
        movie: sampleMovie,
        userSession: UserSession(),
        onDismiss: {},
        onBookmark: {}
    )
}
