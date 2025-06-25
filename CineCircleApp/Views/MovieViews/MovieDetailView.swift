import SwiftData
import SwiftUI

struct MovieDetailView: View {
    // MARK: Private interface

    @State private var viewModel = MovieDetailViewModel()

    // MARK: Internal interface

    let movie: RemoteMovie
    @EnvironmentObject private var userSession: UserSession
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Text(movie.title)
                        .font(titleFont)
                        .bold()

                    Spacer()

                    LogoView()
                }

                HStack {
                    if let posterPath = movie.posterPath,
                       let url = URL(string: posterBaseURL + posterPath) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray)
                                    .frame(maxHeight: .infinity)
                            default:
                                EmptyView()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: detailsSpacing) {
                        if let director = viewModel.director {
                            Text("🎬 ")
                                + Text("Director: ").bold()
                                + Text(director).foregroundStyle(Color.gray)
                        }

                        if let producer = viewModel.producer {
                            Text("Producer: ").bold()
                                + Text(producer).foregroundStyle(Color.gray)
                        }
                        if !viewModel.cast.isEmpty {
                            let actorNames = viewModel.cast.prefix(maxDisplayedActors).map(\.name).joined(separator: ", ")
                            HStack {
                                Text("Cast: ").bold()
                                    + Text(actorNames).foregroundStyle(Color.gray)
                                    + Text(", etc.").foregroundStyle(Color.gray)
                            }
                        }
                        if case let .authenticated(userID) = userSession.authState {
                            VStack(alignment: .leading) {
                                NavigationLink("My notes") {
                                    MovieNoteView(movieId: movie.id, userId: userID)
                                }
                                WatchedCheckboxView(movieID: movie.id, userID: userID)
                            }
                        }

                        Spacer()
                    }
                    .font(infoFont)
                }
                Text("⭐️ \(String(format: ratingFormat, movie.voteAverage))")
                    .font(infoFont)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Text("Release date: \(movie.releaseDate)")
                    .font(infoFont)
                    .fontWeight(.semibold)

                Divider()

                Text(movie.overview)
                    .font(bodyFont)
                    .multilineTextAlignment(.leading)
                    .padding(.top)
            }
            .padding()
            .navigationTitle(movie.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.fetchCastAndCrew(for: movie.id)
        }
    }

    // MARK: Private interface

    private let posterBaseURL = "https://image.tmdb.org/t/p/w500"
    private let maxDisplayedActors = 7
    private let ratingFormat = "%.1f"
    private let detailsSpacing: CGFloat = 15

    private let titleFont = Font.system(.title, design: .rounded)
    private let infoFont = Font.system(.subheadline, design: .rounded)
    private let bodyFont = Font.system(.body, design: .rounded)
}

#Preview {
    let sampleMovie = RemoteMovie(
        id: 675_353,
        title: "Sonic the Hedgehog 2",
        overview: "When Dr. Robotnik returns with a new partner, Knuckles, in search of an emerald that has the power to destroy civilizations, Sonic teams up with his own sidekick, Tails, on a journey across the world to find the emerald first.",
        posterPath: "/6DrHO1jr3qVrViUO6s6kFiAGM7.jpg",
        voteAverage: 7.5,
        releaseDate: "2022-04-08",
    )

    NavigationStack {
        MovieDetailView(movie: sampleMovie)
            .environment(\.authService, FirebaseAuthService())
    }
}
