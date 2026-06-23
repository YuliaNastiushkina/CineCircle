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
            async let details: Void = viewModel.fetchMovieDetails(for: movieID)
            async let castCrew: Void = viewModel.fetchCastAndCrew(for: movieID)
            async let images: Void = viewModel.fetchMovieImages(for: movieID)
            async let trailer: Void = viewModel.fetchMovieTrailer(for: movieID)
            await details
            await castCrew
            await images
            await trailer
        }
    }
}

#Preview {
    MovieDetailViewLoaderView(movieID: 1)
}
