import SwiftUI

struct MovieInfo: View {
    let viewModel: MovieDetailViewModel
    let movie: RemoteMovieDetail

    var body: some View {
        // MARK: - Title + meta info

        VStack(alignment: .leading, spacing: spacing) {
            HStack {
                Text(movie.title)
                    .font(Font.custom(poppinsFont, size: titleFontSize))
                    .fontWeight(.semibold)

                Spacer()

                LogoView()
            }

            HStack(spacing: spacing) {
                Text(movie.releaseDate.prefix(4))

                if !movie.genres.isEmpty {
                    dot()
                    Text(movie.genres.map(\.name).joined(separator: ","))
                        .lineLimit(1)
                }

                if let runtime = movie.runtime {
                    dot()
                    Text("\(runtime / minInHour)h \(runtime % minInHour)m")
                }
            }
            .font(Font.custom(poppinsFont, size: metaFontSize))
            .foregroundColor(.secondary)

            // MARK: - Synopsis

            VStack(alignment: .leading, spacing: spacing) {
                Text(movie.overview)
                    .font(Font.custom(poppinsFont, size: overviewFontSize))
                    .foregroundColor(.primary)
                    .lineLimit(expanded ? nil : lineLimitCollapsed)
                    .animation(.default, value: expanded)

                Button {
                    expanded.toggle()
                } label: {
                    HStack {
                        Text(expanded ? seeLessText : seeMoreText)
                        Image(systemName: "chevron.down")
                            .rotationEffect(expanded ? .degrees(180) : .degrees(0))
                    }
                    .font(Font.custom(poppinsFont, size: metaFontSize))
                    .foregroundColor(.black)
                }
            }
            .padding(.top, overviewSpacing)

            VStack(alignment: .leading, spacing: spacing) {
                // MARK: - Gallery

                SectionHeader(title: "Gallery")
                MovieGallery(images: viewModel.images)
                    .padding(.bottom, sectionSpacing)

                // MARK: - Cast

                SectionHeader(title: "Cast")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.cast) { actor in
                            PersonItemView(
                                name: actor.name,
                                role: nil,
                                profilePath: actor.profilePath,
                                nameLineLimit: 2
                            )
                        }
                    }
                    .padding(.bottom, sectionSpacing)
                }

                // MARK: - Crew

                SectionHeader(title: "Crew")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(essentialCrew) { member in
                            PersonItemView(
                                name: member.name,
                                role: member.job,
                                profilePath: member.profilePath,
                                nameLineLimit: 1
                            )
                        }
                    }
                    .padding(.bottom, sectionSpacing)
                }

                // MARK: - Detailed info

                SectionHeader(title: "Movie Info")
                MovieDetailSpecsView(movie: movie, viewModel: viewModel)
            }
            .padding(.top, sectionSpacing)
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }

    // MARK: - Private interface

    @State private var expanded = false
    private let poppinsFont = "Poppins"
    private let titleFontSize: CGFloat = 20
    private let metaFontSize: CGFloat = 14
    private let overviewFontSize: CGFloat = 16
    private let overviewSpacing: CGFloat = 22
    private let sectionSpacing: CGFloat = 32
    private let spacing: CGFloat = 4
    private let minInHour: Int = 60
    private let lineLimitCollapsed = 3
    private let dotSize: CGFloat = 4
    private let seeMoreText = "See more"
    private let seeLessText = "See less"
    private let fontName = "Poppins"
    private let dotPadding: CGFloat = 5

    @ViewBuilder private func dot() -> some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: dotSize, height: dotSize)
            .padding(dotPadding)
    }

    private var essentialCrew: [MovieCrew] {
        let essentialJobs = [
            "Director",
            "Producer",
            "Executive Producer",
            "Writer",
            "Screenplay",
        ]

        return viewModel.crew
            .filter { essentialJobs.contains($0.job) }
            .sorted { first, second in
                if first.job == "Director" { return true }
                if second.job == "Director" { return false }

                let firstIndex = essentialJobs.firstIndex(of: first.job) ?? Int.max
                let secondIndex = essentialJobs.firstIndex(of: second.job) ?? Int.max

                if firstIndex == secondIndex {
                    return first.name < second.name
                }

                return firstIndex < secondIndex
            }
    }
}

#Preview {
    let sampleMovie = RemoteMovieDetail(id: 675_353,
                                        title: "Sonic the Hedgehog 2",
                                        overview: "When Dr. Robotnik returns with a new partner, Knuckles, in search of an emerald that has the power to destroy civilizations, Sonic teams up with his own sidekick, Tails, on a journey across the world to find the emerald first.",
                                        posterPath: "/6DrHO1jr3qVrViUO6s6kFiAGM7.jpg", backdropPath: "", voteAverage: 7.5,
                                        releaseDate: "2022-04-08", runtime: 121, originalLanguage: "EN", genres: [RemoteMovieDetail.Genre(id: 1, name: "Fiction")], productionCompanies: [RemoteMovieDetail.ProductionCompany(id: 1, name: "Paramount Pictures")])
    NavigationStack {
        MovieInfo(viewModel: MovieDetailViewModel(), movie: sampleMovie)
            .environment(\.authService, FirebaseAuthService())
    }
}
