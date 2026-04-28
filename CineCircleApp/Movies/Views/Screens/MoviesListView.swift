import CoreData
import SwiftData
import SwiftUI

struct MoviesListView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var userSession: UserSession

    @State private var isLoading = false
    @State private var viewModel = MovieListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else if viewModel.displayedMovies.isEmpty {
                    ContentUnavailableView(viewModel.showSavedOnly ? "No Saved Movies" : "No Movies Found",
                                           systemImage: "film.stack")
                } else {
                    List(viewModel.displayedMovies, id: \.id) { movie in
                        NavigationLink {
                            MovieDetailViewLoaderView(movieID: movie.id)
                        } label: {
                            MovieListRow(movie: movie)
                        }
                        .listRowSeparator(.hidden)
                        .task {
                            if movie.id == viewModel.movies.last?.id {
                                await viewModel.fetchNextPageIfNeeded(currentMovie: movie)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(viewModel.showSavedOnly ? "Saved" : "Popular Movies")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            viewModel.showSavedOnly.toggle()
                            if viewModel.showSavedOnly { loadSavedIDs() }
                        } label: {
                            Label("Saved", systemImage: viewModel.showSavedOnly ? "bookmark.fill" : "bookmark")
                        }

                        Button {
                            viewModel.isSorted.toggle()
                        } label: {
                            Label("Sort A–Z", systemImage: "arrow.up.arrow.down")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    LogoView()
                }
            }
        }
        .searchable(text: $viewModel.filterText)
        .task {
            if viewModel.movies.isEmpty {
                await loadMovies()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear(perform: loadSavedIDs)
        .onReceive(userSession.$authState) { _ in
            loadSavedIDs()
        }
    }

    // MARK: - Private interface

    private func loadMovies() async {
        isLoading = true
        await viewModel.fetchPopularMovies()
        isLoading = false
    }

    private func loadSavedIDs() {
        guard case let .authenticated(userId) = userSession.authState else {
            viewModel.savedIDs = []; return
        }
        let request: NSFetchRequest<SavedMovie> = SavedMovie.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userId)
        request.sortDescriptors = []
        let results = (try? context.fetch(request)) ?? []
        viewModel.savedIDs = Set(results.map { Int($0.movieID) })
    }
}

private struct MovieListRow: View {
    let movie: RemoteMovie

    @State private var movieDetail: RemoteMovieDetail?

    private let apiClient = APIClient()
    private let genreLookup: [Int: String] = [
        28: "Action",
        12: "Adventure",
        16: "Animation",
        35: "Comedy",
        80: "Crime",
        99: "Documentary",
        18: "Drama",
        10751: "Family",
        14: "Fantasy",
        36: "History",
        27: "Horror",
        10402: "Music",
        9648: "Mystery",
        10749: "Romance",
        878: "Sci-Fi",
        10770: "TV Movie",
        53: "Thriller",
        10752: "War",
        37: "Western",
    ]

    var body: some View {
        HStack(alignment: .top, spacing: Parameters.rowSpacing) {
            posterImage
            movieInfo
        }
        .padding(.vertical, Parameters.rowVerticalPadding)
        .task {
            await loadMovieDetailIfNeeded()
        }
    }

    private var posterImage: some View {
        Group {
            if let path = movie.posterPath {
                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w342\(path)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    posterPlaceholder
                }
            } else {
                posterPlaceholder
            }
        }
        .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: Parameters.posterCornerRadius))
        .clipped()
    }

    private var posterPlaceholder: some View {
        PosterPlaceholderView(
            cornerRadius: Parameters.posterCornerRadius,
            iconSize: Parameters.placeholderIconSize
        )
    }

    private var movieInfo: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            Text(movie.title)
                .font(Font.custom(AppUI.FontName.poppinsLight, size: Parameters.titleFontSize))
                .foregroundColor(.primary)
                .lineLimit(2)
                .padding(.bottom, Parameters.titleBottomPadding)

            HStack(spacing: Parameters.metadataSpacing) {
                metadataChip(text: releaseYear)

                if let runtimeText {
                    metadataChip(text: runtimeText)
                }

                if !languageText.isEmpty {
                    metadataChip(text: languageText)
                }
            }

            if !genreLine.isEmpty {
                metadataChip(text: genreLine)
            }

            Spacer()

            HStack(spacing: Parameters.ratingSpacing) {
                Text(String(format: "%.1f", movie.voteAverage))
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.ratingFontSize))
                    .foregroundColor(.primary)

                Image(systemName: "star.fill")
                    .foregroundColor(AppUI.ColorPalette.accent)
                    .font(.system(size: Parameters.ratingFontSize))

                Text("(\(ratingCount))")
                    .font(Font.custom(AppUI.FontName.poppinsLight, size: Parameters.ratingFontSize))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var releaseYear: String {
        let year = String(movie.releaseDate.prefix(4))
        return year.isEmpty ? "TBA" : year
    }

    private var runtimeText: String? {
        guard let movieDetail else { return nil }
        let text = MovieFormatter.runtimeText(minutes: movieDetail.runtime)
        return text == "—" ? nil : text
    }

    private var languageText: String {
        let language = movieDetail?.originalLanguage ?? movie.originalLanguage
        return language.uppercased()
    }

    private var genreTexts: [String] {
        if let movieDetail, !movieDetail.genres.isEmpty {
            return Array(movieDetail.genres.map(\.name).prefix(3))
        }

        return movie.genreIDs.compactMap { genreLookup[$0] }.prefix(3).map { $0 }
    }

    private var genreLine: String {
        genreTexts.joined(separator: ", ")
    }

    private var ratingCount: Int {
        movieDetail?.voteCount ?? movie.voteCount
    }

    @ViewBuilder private func metadataChip(text: String) -> some View {
        MetadataChip(
            text: text,
            font: Font.custom(AppUI.FontName.poppinsLight, size: Parameters.metadataFontSize),
            horizontalPadding: Parameters.metadataHorizontalPadding,
            verticalPadding: Parameters.metadataVerticalPadding
        )
    }

    private func loadMovieDetailIfNeeded() async {
        guard movieDetail == nil else { return }

        do {
            movieDetail = try await apiClient.fetch(
                path: "movie/\(movie.id)",
                query: [:],
                responseType: RemoteMovieDetail.self
            )
        } catch {
            // Keep the row usable with the basic list data if detail loading fails.
        }
    }

    private enum Parameters {
        static let rowSpacing: CGFloat = 12
        static let rowVerticalPadding: CGFloat = 2
        static let posterWidth: CGFloat = 124
        static let posterHeight: CGFloat = 186
        static let posterCornerRadius: CGFloat = AppUI.Radius.medium
        static let placeholderIconSize: CGFloat = 24
        static let contentSpacing: CGFloat = 10
        static let titleFontSize: CGFloat = 20
        static let titleBottomPadding: CGFloat = 10
        static let metadataSpacing: CGFloat = 8
        static let metadataFontSize: CGFloat = 14
        static let metadataHorizontalPadding: CGFloat = 10
        static let metadataVerticalPadding: CGFloat = 4
        static let ratingSpacing: CGFloat = 6
        static let ratingFontSize: CGFloat = 14
    }
}

#Preview {
    MoviesListView()
        .environmentObject(UserSession())
}
