import SwiftUI

struct MovieScreenView: View {
    @Bindable var viewModel: MovieDetailViewModel
    @EnvironmentObject private var userSession: UserSession

    let movie: RemoteMovieDetail

    var body: some View {
        MediaDetailContainer { dismiss in
            MoviePosterSectionView(
                movie: movie,
                userSession: userSession,
                onDismiss: dismiss,
                onBookmark: {}
            )
        } content: {
            MovieInfoSummaryView(viewModel: viewModel, movie: movie)
        } bottomInset: {
            if case let .authenticated(userID) = userSession.authState {
                MovieDiaryButton(movieId: movie.id, userId: userID, movieTitle: movie.title)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
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

    NavigationStack {
        MovieScreenView(viewModel: MovieDetailViewModel(), movie: sampleMovie)
            .environmentObject(UserSession())
    }
}
