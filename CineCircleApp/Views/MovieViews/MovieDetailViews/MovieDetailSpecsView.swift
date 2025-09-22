import SwiftUI

struct MovieDetailSpecsView: View {
    let movie: RemoteMovieDetail
    @Bindable var viewModel: MovieDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Synopsis")
                .font(Font.custom(poppinsFont, size: 14))
                .foregroundStyle(Color(white: 0.32))

            Text(movie.overview)
                .font(Font.custom(poppinsFont, size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            infoRow(title: "Director", value: viewModel.detailsPresentation.directors)
            infoRow(title: "Producer", value: viewModel.detailsPresentation.producers)
            infoRow(title: "Screenwriter", value: viewModel.detailsPresentation.screenwriters)
            infoRow(title: "Production Co", value: viewModel.detailsPresentation.productionCompanies)
            infoRow(title: "Genre", value: viewModel.detailsPresentation.genres)
            infoRow(title: "Original Language", value: viewModel.detailsPresentation.originalLanguage)
            infoRow(title: "Release Date (Streaming)", value: formattedDate(viewModel.detailsPresentation.releaseDate))
            infoRow(title: "Runtime", value: viewModel.detailsPresentation.runtime)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.secondary.opacity(0.04))
        .cornerRadius(24)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.custom(poppinsFont, size: 14))
                    .foregroundStyle(Color(white: 0.32))

                Text(value.isEmpty ? "—" : value)
                    .font(Font.custom(poppinsFont, size: 14))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func formattedDate(_ input: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"

        if let date = inputFormatter.date(from: input) {
            return outputFormatter.string(from: date)
        } else {
            return input
        }
    }

    // MARK: - Constants

    private let poppinsFont = "Poppins"
}

#Preview {
    let sampleMovie = RemoteMovieDetail(
        id: 1,
        title: "Sample",
        overview: "Overview",
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 7.3,
        releaseDate: "2025-01-01",
        runtime: 121,
        originalLanguage: "en",
        genres: [RemoteMovieDetail.Genre(id: 1, name: "Action"), .init(id: 2, name: "Sci-Fi")],
        productionCompanies: [RemoteMovieDetail.ProductionCompany(id: 1, name: "Paramount")]
    )
    MovieDetailSpecsView(movie: sampleMovie, viewModel: MovieDetailViewModel())
}
