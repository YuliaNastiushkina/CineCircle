import SwiftData
import SwiftUI

struct MovieDetailView: View {
    // MARK: Private interface

    @State private var viewModel = MovieDetailViewModel()
    @EnvironmentObject private var userSession: UserSession
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: Internal interface

    let movie: RemoteMovieDetail

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: Poster + overlay buttons

            ZStack(alignment: .top) {
                GeometryReader { proxy in
                    if let posterPath = movie.posterPath,
                       let url = URL(string: posterBaseURL + posterPath) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            default:
                                Color.gray
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                            }
                        }
                    }
                }
                .ignoresSafeArea()

                HStack {
                    overlayButton(systemName: "chevron.left", action: { dismiss() })
                    Spacer()
                    overlayButton(systemName: "bookmark.fill", action: { /* save */ })
                }
                .padding()

                // MARK: Rating + status row

                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        HStack {
                            Text(String(format: ratingFormat, movie.voteAverage))
                                .font(Font.custom(poppinsFont, size: ratingFontSize))
                                .foregroundColor(.white)

                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(Font.custom(poppinsFont, size: ratingFontSize))
                        }
                        .padding(.vertical, ratingPaddingV)
                        .padding(.horizontal, ratingPaddingH)
                        .background(ratingBackgroundColor)
                        .clipShape(Capsule())

                        Spacer()

                        if case let .authenticated(userID) = userSession.authState {
                            WatchStatusButton(movieID: movie.id, userID: userID)
                                .padding(.vertical, ratingPaddingV)
                                .padding(.horizontal, ratingPaddingH)
                                .background(ratingBackgroundColor)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, bottomPadding)
                }
            }
            .frame(height: zStackHeight)

            ScrollView {
                MovieInfo(movie: movie)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    // MARK: Private interface

    private let posterBaseURL = "https://image.tmdb.org/t/p/w500"
    private let ratingFormat = "%.1f"
    private let poppinsFont = "Poppins"
    private let zStackHeight: CGFloat = 427
    private let overlayCircleSize: CGFloat = 45
    private let overlayCircleOpacity: Double = 0.8
    private let overlayCircleColor: Double = 0.32
    private let buttonIconFontSize: CGFloat = 20
    private let ratingFontSize: CGFloat = 16
    private let ratingPaddingV: CGFloat = 10
    private let ratingPaddingH: CGFloat = 16
    private let ratingBackgroundColor = Color(white: 0.32).opacity(0.8)
    private let spacingBetweenRatingAndStatus: CGFloat = 12
    private let bottomPadding: CGFloat = 24

    private func overlayButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color(white: overlayCircleColor, opacity: overlayCircleOpacity))
                .frame(width: overlayCircleSize, height: overlayCircleSize)
                .overlay(
                    Image(systemName: systemName)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .font(.system(size: buttonIconFontSize))
                )
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
        MovieDetailView(movie: sampleMovie)
            .environment(\.authService, FirebaseAuthService())
    }
}
