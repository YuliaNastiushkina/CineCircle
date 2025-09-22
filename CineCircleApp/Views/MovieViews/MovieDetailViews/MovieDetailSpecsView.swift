import SwiftUI

struct MovieDetailSpecsView: View {
    let movie: RemoteMovieDetail
    @Bindable var viewModel: MovieDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            Text("Synopsis")
                .font(Font.custom(poppinsFont, size: labelFontSize))
                .foregroundStyle(labelColor)

            Text(movie.overview)
                .font(Font.custom(poppinsFont, size: labelFontSize))
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
        .padding(containerPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(containerBackground)
        .cornerRadius(containerCornerRadius)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: horizontalSpacing) {
            VStack(alignment: .leading, spacing: innerSpacing) {
                Text(title)
                    .font(Font.custom(poppinsFont, size: labelFontSize))
                    .foregroundStyle(labelColor)

                Text(value.isEmpty ? emptyValuePlaceholder : value)
                    .font(Font.custom(poppinsFont, size: labelFontSize))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func formattedDate(_ input: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = apiDateFormat

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = displayDateFormat

        if let date = inputFormatter.date(from: input) {
            return outputFormatter.string(from: date)
        } else {
            return input
        }
    }

    // MARK: - Constants

    private let poppinsFont = "Poppins"
    private let verticalSpacing: CGFloat = 12
    private let horizontalSpacing: CGFloat = 12
    private let innerSpacing: CGFloat = 4
    private let containerPadding: CGFloat = 16
    private let containerCornerRadius: CGFloat = 24
    private let labelFontSize: CGFloat = 14
    private let valueFontSize: CGFloat = 14
    private let labelColor = Color(white: 0.32)
    private let containerBackground = Color.secondary.opacity(0.04)
    private let emptyValuePlaceholder = "—"
    private let apiDateFormat = "yyyy-MM-dd"
    private let displayDateFormat = "MMM d, yyyy"
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
