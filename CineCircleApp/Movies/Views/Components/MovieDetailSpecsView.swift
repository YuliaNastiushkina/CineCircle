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

            personInfoRow(title: "Director", jobs: ["Director"])
            personInfoRow(title: "Producer", jobs: ["Producer"])
            personInfoRow(title: "Screenwriter", jobs: ["Writer", "Screenplay", "Story"])
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

    private func personInfoRow(title: String, jobs: [String]) -> some View {
        let people = people(for: jobs)

        return HStack(alignment: .top, spacing: Parameters.horizontalSpacing) {
            VStack(alignment: .leading, spacing: Parameters.innerSpacing) {
                Text(title)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.labelFontSize))
                    .foregroundStyle(Parameters.labelColor)

                if people.isEmpty {
                    Text(Parameters.emptyValuePlaceholder)
                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.labelFontSize))
                        .foregroundStyle(.primary)
                } else {
                    FlowLayout(spacing: 0) {
                        ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                            NavigationLink {
                                CrewPersonDetailView(
                                    personID: person.id,
                                    name: person.name,
                                    role: person.job,
                                    profilePath: person.profilePath
                                )
                            } label: {
                                Text(person.name + (index < people.count - 1 ? ", " : ""))
                                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.labelFontSize))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Parameters.personLinkColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxHeight: Parameters.peopleMaxHeight, alignment: .topLeading)
                    .clipped()
                }
            }
        }
    }

    private func people(for jobs: [String]) -> [MovieCrew] {
        let targetJobs = Set(jobs)

        return viewModel.crew
            .filter { member in
                Set(jobList(from: member.job)).isDisjoint(with: targetJobs) == false
            }
            .sorted { first, second in
                let firstPriority = topPriorityIndex(for: first, in: jobs)
                let secondPriority = topPriorityIndex(for: second, in: jobs)

                if firstPriority == secondPriority {
                    return first.name < second.name
                }

                return firstPriority < secondPriority
            }
    }

    private func jobList(from value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func topPriorityIndex(for member: MovieCrew, in jobs: [String]) -> Int {
        jobList(from: member.job)
            .compactMap { jobs.firstIndex(of: $0) }
            .min() ?? Int.max
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
        static let peopleMaxHeight: CGFloat = 60
        static let labelColor = Color(white: 0.32)
        static let personLinkColor = Color(white: 0.12)
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
