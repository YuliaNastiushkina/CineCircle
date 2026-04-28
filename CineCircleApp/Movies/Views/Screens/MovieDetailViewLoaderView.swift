import SwiftUI

struct MovieDetailViewLoaderView: View {
    let movieID: Int
    @State private var viewModel = MovieDetailViewModel()

    var body: some View {
        Group {
            if let movie = viewModel.movieDetail {
                MovieScreenView(viewModel: viewModel, movie: movie)
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.fetchMovieDetails(for: movieID)
            await viewModel.fetchCastAndCrew(for: movieID)
            await viewModel.fetchMovieImages(for: movieID)
        }
    }
}

#Preview {
    MovieDetailViewLoaderView(movieID: 1)
}
