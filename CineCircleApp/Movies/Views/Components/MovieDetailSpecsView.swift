import SwiftUI

struct MovieDetailSpecsView: View {
    let movie: RemoteMovieDetail
    @Bindable var viewModel: MovieDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.verticalSpacing) {
            Text("Synopsis")
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.labelFontSize))
                .foregroundStyle(Parameters.labelColor)

            Text(movie.overview)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.labelFontSize))
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
        .padding(Parameters.containerPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Parameters.containerBackground)
        .cornerRadius(AppUI.Radius.card)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: Parameters.horizontalSpacing) {
            VStack(alignment: .leading, spacing: Parameters.innerSpacing) {
                Text(title)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.labelFontSize))
                    .foregroundStyle(Parameters.labelColor)

                Text(value.isEmpty ? Parameters.emptyValuePlaceholder : value)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.labelFontSize))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func formattedDate(_ input: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = Parameters.apiDateFormat

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = Parameters.displayDateFormat

        if let date = inputFormatter.date(from: input) {
            return outputFormatter.string(from: date)
        } else {
            return input
        }
    }

    // MARK: - Constants

    private enum Parameters {
        static let verticalSpacing: CGFloat = 12
        static let horizontalSpacing: CGFloat = 12
        static let innerSpacing: CGFloat = 4
        static let containerPadding: CGFloat = 16
        static let labelFontSize: CGFloat = 14
        static let labelColor = Color(white: 0.32)
        static let containerBackground = Color.secondary.opacity(0.04)
        static let emptyValuePlaceholder = "—"
        static let apiDateFormat = "yyyy-MM-dd"
        static let displayDateFormat = "MMM d, yyyy"
    }
}

#Preview {
    let sampleMovie = RemoteMovieDetail(
        id: 1,
        title: "Sample",
        overview: "Overview",
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 7.3,
        voteCount: 321,
        releaseDate: "2025-01-01",
        runtime: 121,
        originalLanguage: "en",
        genres: [RemoteMovieDetail.Genre(id: 1, name: "Action"), .init(id: 2, name: "Sci-Fi")],
        productionCompanies: [RemoteMovieDetail.ProductionCompany(id: 1, name: "Paramount")]
    )
    MovieDetailSpecsView(movie: sampleMovie, viewModel: MovieDetailViewModel())
}
