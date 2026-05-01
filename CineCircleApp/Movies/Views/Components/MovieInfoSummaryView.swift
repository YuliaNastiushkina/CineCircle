import SwiftUI

struct MovieInfoSummaryView: View {
    let viewModel: MovieDetailViewModel
    let movie: RemoteMovieDetail
    
    @Environment(\.openURL) private var openURL

    var body: some View {
        // MARK: - Title + meta info

        VStack(alignment: .leading, spacing: Parameters.baseSpacing) {
            HStack {
                Text(movie.title)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.titleFontSize))
                    .fontWeight(.semibold)

                Spacer()

                LogoView()
            }

            HStack(spacing: Parameters.baseSpacing) {
                Text(movie.releaseDate.prefix(4))

                if !movie.genres.isEmpty {
                    dot()
                    Text(movie.genres.map(\.name).joined(separator: ","))
                        .lineLimit(1)
                }

                if let runtime = movie.runtime {
                    dot()
                    Text("\(runtime / Parameters.minutesInHour)h \(runtime % Parameters.minutesInHour)m")
                }
            }
            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.metaFontSize))
            .foregroundColor(.secondary)

            // MARK: - Synopsis

            VStack(alignment: .leading, spacing: Parameters.baseSpacing) {
                Text(movie.overview)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.overviewFontSize))
                    .foregroundColor(.primary)
                    .lineLimit(expanded ? nil : Parameters.lineLimitCollapsed)
                    .animation(.default, value: expanded)

                Button {
                    expanded.toggle()
                } label: {
                    HStack {
                        Text(expanded ? Parameters.seeLessText : Parameters.seeMoreText)
                        Image(systemName: "chevron.down")
                            .rotationEffect(expanded ? .degrees(180) : .degrees(0))
                    }
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.metaFontSize))
                    .foregroundColor(.black)
                }
            }
            .padding(.top, Parameters.overviewTopPadding)

            VStack(alignment: .leading, spacing: Parameters.baseSpacing) {
                // MARK: - Trailer

                SectionTitleView(title: "Trailer")
                Group {
                    if let trailer = viewModel.trailer {
                        MovieTrailerView(trailer: trailer) {
                            if let url = trailer.youtubeWatchURL {
                                openURL(url)
                            }
                        }
                    } else if viewModel.hasLoadedTrailer {
                        trailerEmptyState
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Parameters.trailerLoadingPadding)
                    }
                }
                .padding(.bottom, Parameters.sectionSpacing)

                // MARK: - Gallery

                SectionTitleView(title: "Gallery")
                MovieImageGalleryView(images: viewModel.images)
                    .padding(.bottom, Parameters.sectionSpacing)

                // MARK: - Cast

                SectionTitleView(title: "Cast")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.cast) { actor in
                            NavigationLink {
                                CrewPersonDetailView(
                                    personID: actor.id,
                                    name: actor.name,
                                    role: nil,
                                    profilePath: actor.profilePath
                                )
                            } label: {
                                PersonChipView(
                                    name: actor.name,
                                    role: nil,
                                    profilePath: actor.profilePath,
                                    nameLineLimit: 2
                                )
                            }
                        }
                    }
                    .padding(.bottom, Parameters.sectionSpacing)
                }

                // MARK: - Crew

                SectionTitleView(title: "Crew")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(essentialCrew.enumerated()), id: \.offset) { _, member in
                            NavigationLink {
                                CrewPersonDetailView(
                                    personID: member.id,
                                    name: member.name,
                                    role: member.job,
                                    profilePath: member.profilePath
                                )
                            } label: {
                                PersonChipView(
                                    name: member.name,
                                    role: member.job,
                                    profilePath: member.profilePath,
                                    nameLineLimit: 1
                                )
                            }
                        }
                    }
                    .padding(.bottom, Parameters.sectionSpacing)
                }

                // MARK: - Detailed info

                SectionTitleView(title: "Movie Info")
                MovieDetailSpecsView(movie: movie, viewModel: viewModel)
            }
            .padding(.top, Parameters.sectionSpacing)
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }

    // MARK: - Private interface

    @State private var expanded = false
    private enum Parameters {
        static let titleFontSize: CGFloat = 20
        static let metaFontSize: CGFloat = 14
        static let overviewFontSize: CGFloat = 16
        static let overviewTopPadding: CGFloat = 22
        static let sectionSpacing: CGFloat = 32
        static let baseSpacing: CGFloat = 4
        static let minutesInHour: Int = 60
        static let lineLimitCollapsed = 3
        static let dotSize: CGFloat = 4
        static let dotPadding: CGFloat = 5
        static let seeMoreText = "See more"
        static let seeLessText = "See less"
        static let emptyStatePadding: CGFloat = 16
        static let emptyStateSpacing: CGFloat = 6
        static let emptyStateCornerRadius: CGFloat = 16
        static let emptyStateBackgroundOpacity: CGFloat = 0.12
        static let emptyStateTitleFontSize: CGFloat = 15
        static let emptyStateMessageFontSize: CGFloat = 13
        static let trailerLoadingPadding: CGFloat = 40
    }

    @ViewBuilder private func dot() -> some View {
        Circle()
            .fill(AppUI.ColorPalette.accent)
            .frame(width: Parameters.dotSize, height: Parameters.dotSize)
            .padding(Parameters.dotPadding)
    }

    private var trailerEmptyState: some View {
        VStack(alignment: .leading, spacing: Parameters.emptyStateSpacing) {
            Text("No trailer available")
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.emptyStateTitleFontSize))
                .foregroundStyle(.primary)

            Text("This movie does not currently have a trailer in TMDB.")
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.emptyStateMessageFontSize))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Parameters.emptyStatePadding)
        .background(Color.secondary.opacity(Parameters.emptyStateBackgroundOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Parameters.emptyStateCornerRadius))
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
            .filter { member in
                memberJobs(for: member).contains { essentialJobs.contains($0) }
            }
            .sorted { first, second in
                let firstIndex = topPriorityIndex(for: first, in: essentialJobs)
                let secondIndex = topPriorityIndex(for: second, in: essentialJobs)

                if firstIndex == secondIndex {
                    return first.name < second.name
                }

                return firstIndex < secondIndex
            }
    }

    private func memberJobs(for member: MovieCrew) -> [String] {
        member.job
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func topPriorityIndex(for member: MovieCrew, in essentialJobs: [String]) -> Int {
        memberJobs(for: member)
            .compactMap { essentialJobs.firstIndex(of: $0) }
            .min() ?? Int.max
    }
}

#Preview {
    let sampleMovie = RemoteMovieDetail(id: 675_353,
                                        title: "Sonic the Hedgehog 2",
                                        overview: "When Dr. Robotnik returns with a new partner, Knuckles, in search of an emerald that has the power to destroy civilizations, Sonic teams up with his own sidekick, Tails, on a journey across the world to find the emerald first.",
                                        posterPath: "/6DrHO1jr3qVrViUO6s6kFiAGM7.jpg", backdropPath: "", voteAverage: 7.5, voteCount: 1543,
                                        releaseDate: "2022-04-08", runtime: 121, originalLanguage: "EN", genres: [RemoteMovieDetail.Genre(id: 1, name: "Fiction")], productionCompanies: [RemoteMovieDetail.ProductionCompany(id: 1, name: "Paramount Pictures")])
    NavigationStack {
        MovieInfoSummaryView(viewModel: MovieDetailViewModel(), movie: sampleMovie)
            .environment(\.authService, FirebaseAuthService())
    }
}
