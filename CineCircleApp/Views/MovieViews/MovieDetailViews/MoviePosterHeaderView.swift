import SwiftUI

struct MoviePosterSectionView: View {
    // MARK: - Properties

    let movie: RemoteMovieDetail
    let userSession: UserSession
    let onDismiss: () -> Void
    let onBookmark: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                posterImage(geometry: geometry)
                overlayContent(geometry: geometry)
            }
            .frame(height: geometry.size.height * Constants.posterContainerHeightRatio)
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Constants

    private enum Constants {
        static let posterBaseURL = "https://image.tmdb.org/t/p/w500"
        static let poppinsFont = "Poppins"
        static let ratingFormat = "%.1f"

        // UI Constants
//        static let overlayCircleSize: CGFloat = 45
//        static let overlayCircleOpacity: Double = 0.8
//        static let overlayCircleColor: Double = 0.32
//        static let buttonIconFontSize: CGFloat = 20
        static let ratingFontSize: CGFloat = 16
        static let ratingPaddingVertical: CGFloat = 10
        static let ratingPaddingHorizontal: CGFloat = 16
        static let bottomPadding: CGFloat = 24
        static let topPadding: CGFloat = 84

        // Layout Constants
        static let posterHeightRatio: CGFloat = 0.7
        static let overlayHeightRatio: CGFloat = 0.66
        static let posterContainerHeightRatio: CGFloat = 0.5
    }

    private var ratingBackgroundColor: Color {
        Color(white: 0.32).opacity(0.8)
    }

    // MARK: - Private Views

    private func posterImage(geometry: GeometryProxy) -> some View {
        Group {
            if let posterPath = movie.posterPath,
               let url = URL(string: Constants.posterBaseURL + posterPath) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height * Constants.posterHeightRatio
                            )
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height * Constants.posterHeightRatio
                            )
                            .clipped()
                    default:
                        Color.gray
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height * Constants.posterHeightRatio
                            )
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
    }

    private func overlayContent(geometry: GeometryProxy) -> some View {
        VStack {
            topOverlayButtons
            Spacer()
            bottomOverlayContent
        }
        .frame(height: geometry.size.height * Constants.overlayHeightRatio)
    }

    private var topOverlayButtons: some View {
        HStack {
            CircleButton(systemName: "chevron.left", action: onDismiss)
                .foregroundStyle(Color.white)
            Spacer()
            if case let .authenticated(userId) = userSession.authState {
                BookmarkButton(movieID: movie.id, userID: userId)
            }
        }
        .padding(.horizontal)
        .padding(.top, Constants.topPadding)
    }

    private var bottomOverlayContent: some View {
        HStack {
            ratingView
            Spacer()
            watchStatusView
        }
        .padding(.horizontal)
        .padding(.bottom, Constants.bottomPadding)
    }

    private var ratingView: some View {
        HStack {
            Text(String(format: Constants.ratingFormat, movie.voteAverage))
                .font(Font.custom(Constants.poppinsFont, size: Constants.ratingFontSize))
                .foregroundColor(.white)

            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(Font.custom(Constants.poppinsFont, size: Constants.ratingFontSize))
        }
        .padding(.vertical, Constants.ratingPaddingVertical)
        .padding(.horizontal, Constants.ratingPaddingHorizontal)
        .background(ratingBackgroundColor)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var watchStatusView: some View {
        if case let .authenticated(userID) = userSession.authState {
            WatchStatusButton(movieID: movie.id, userID: userID)
                .padding(.vertical, Constants.ratingPaddingVertical)
                .padding(.horizontal, Constants.ratingPaddingHorizontal)
                .background(ratingBackgroundColor)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleMovie = RemoteMovieDetail(
        id: 675_353,
        title: "Sonic the Hedgehog 2",
        overview: "When Dr. Robotnik returns with a new partner, Knuckles, in search of an emerald that has the power to destroy civilizations, Sonic teams up with his own sidekick, Tails, on a journey across the world to find the emerald first.",
        posterPath: "/6DrHO1jr3qVrViUO6s6kFiAGM7.jpg",
        backdropPath: "",
        voteAverage: 7.5,
        releaseDate: "2022-04-08",
        runtime: 121,
        originalLanguage: "EN",
        genres: [RemoteMovieDetail.Genre(id: 1, name: "Fiction")],
        productionCompanies: [RemoteMovieDetail.ProductionCompany(id: 1, name: "Paramount Pictures")]
    )

    MoviePosterSectionView(
        movie: sampleMovie,
        userSession: UserSession(),
        onDismiss: {},
        onBookmark: {}
    )
}
