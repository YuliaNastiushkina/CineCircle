import SwiftData
import SwiftUI

struct MovieDetailView: View {
    // MARK: - Private interface

    @Bindable var viewModel: MovieDetailViewModel
    @EnvironmentObject private var userSession: UserSession
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showingBottomSheet = true

    // MARK: - Internal interface

    let movie: RemoteMovieDetail

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                PosterSectionView(
                    movie: movie,
                    userSession: userSession,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingBottomSheet = false
                        }
                        dismiss()
                    },
                    onBookmark: {}
                )
            }
            .sheet(isPresented: $showingBottomSheet) {
                ScrollView {
                    MovieInfo(viewModel: viewModel, movie: movie)
                        .padding(.top)
                }
                .safeAreaInset(edge: .bottom) {
                    if case let .authenticated(userId) = userSession.authState {
                        NoteButton(movieId: movie.id, userId: userId)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                    }
                }
                .interactiveDismissDisabled()
                .presentationDragIndicator(.hidden)
                .presentationDetents([.fraction(0.47), .large])
                .presentationBackgroundInteraction(
                    .enabled(upThrough: .large)
                )
                .presentationCornerRadius(24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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
        MovieDetailView(viewModel: MovieDetailViewModel(), movie: sampleMovie)
            .environment(\.authService, FirebaseAuthService())
    }
}
