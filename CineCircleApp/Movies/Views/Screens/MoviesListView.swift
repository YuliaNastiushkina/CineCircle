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
                    } else if viewModel.isSearching, viewModel.displayedMovies.isEmpty {
                        ProgressView("Searching...")
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
                                await viewModel.fetchNextPageIfNeeded(currentMovie: movie)
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
        .searchable(text: $viewModel.filterText, prompt: "Search movies")
        .onChange(of: viewModel.filterText) { _, _ in
            viewModel.scheduleSearch()
        }
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
        if !viewModel.filterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No Movies Found"
        }

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
        MediaListRow(
            title: movie.title,
            posterPath: movie.posterPath,
            primaryMetadata: releaseYear,
            secondaryMetadata: runtimeText,
            language: languageText,
            genres: genreLine,
            rating: movie.voteAverage,
            ratingCount: ratingCount
        )
        .task {
            await loadMovieDetailIfNeeded()
        }
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
}

#Preview {
    MoviesListView(userId: "previewUser")
        .environmentObject(UserSession())
}
