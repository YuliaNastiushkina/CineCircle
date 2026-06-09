import CoreData
import SwiftData
import SwiftUI

struct MoviesListView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var userSession: UserSession

    let userId: String

    @State private var viewModel = MovieListViewModel()
    @State private var favoriteGenres: [MoviesGenre] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                genreFilter

                Group {
                    if viewModel.isLoading, viewModel.movies.isEmpty {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.displayedMovies.isEmpty {
                        ContentUnavailableView(emptyStateTitle, systemImage: "film.stack")
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
            }
            .navigationTitle(navigationTitle)
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
            loadFavoriteGenres()
            if viewModel.movies.isEmpty {
                await viewModel.fetchAllMovies()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            loadSavedIDs()
            loadFavoriteGenres()
        }
        .onReceive(userSession.$authState) { _ in
            loadSavedIDs()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileFavoriteGenresDidChange)) { notification in
            guard notification.userInfo?["userID"] as? String == userId else { return }
            loadFavoriteGenres()
        }
    }

    // MARK: - Private interface

    private var navigationTitle: String {
        let title: String = switch viewModel.selectedFilter {
        case .all: "Movies"
        case .popular: "Popular Movies"
        case let .genre(genre): genre.displayName
        }
        return viewModel.showSavedOnly ? "Saved \(title)" : title
    }

    private var emptyStateTitle: String {
        let title = switch viewModel.selectedFilter {
        case .all: "Movies"
        case .popular: "Popular Movies"
        case let .genre(genre): "\(genre.displayName) Movies"
        }
        return viewModel.showSavedOnly ? "No Saved \(title)" : "No \(title) Found"
    }

    private var orderedGenres: [MoviesGenre] {
        favoriteGenres + MoviesGenre.allCases.filter { !favoriteGenres.contains($0) }
    }

    private var genreFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(title: "All", filter: .all)
                filterButton(title: "Popular", filter: .popular)

                ForEach(orderedGenres) { genre in
                    filterButton(title: genre.displayName, filter: .genre(genre))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private func filterButton(title: String, filter: MovieListFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter

        return Button {
            guard viewModel.selectedFilter != filter else { return }
            Task {
                await viewModel.selectFilter(filter)
            }
        } label: {
            Text(title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 13))
                .foregroundColor(isSelected ? .black : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppUI.ColorPalette.accent : AppUI.ColorPalette.secondarySurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func loadFavoriteGenres() {
        let stored = UserDefaults.standard.stringArray(
            forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userId)
        ) ?? []
        favoriteGenres = stored.compactMap(MoviesGenre.fromStoredValue).reduce(into: []) { result, genre in
            if !result.contains(genre) {
                result.append(genre)
            }
        }
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

        return movie.genreIDs.compactMap { MoviesGenre.genre(forTMDBID: $0)?.displayName }.prefix(3).map { $0 }
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
    MoviesListView(userId: "previewUser")
        .environmentObject(UserSession())
}
