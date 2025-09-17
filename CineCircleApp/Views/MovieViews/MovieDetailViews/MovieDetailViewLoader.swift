
import SwiftUI

struct MovieDetailViewLoader: View {
    let movieID: Int
    @State private var viewModel = MovieDetailViewModel()

    var body: some View {
        Group {
            if let movie = viewModel.movieDetail {
                AnyView(MovieDetailView(movie: movie))
            } else {
                AnyView(ProgressView())
            }
        }
        .task {
            await viewModel.fetchMovieDetails(for: movieID)
            await viewModel.fetchCastAndCrew(for: movieID)
        }
    }
}

#Preview {
    MovieDetailViewLoader(movieID: 1)
}
