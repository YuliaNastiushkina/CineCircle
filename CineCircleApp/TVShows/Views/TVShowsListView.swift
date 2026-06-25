import SwiftUI

struct TVShowsListView: View {
    let userID: String

    @State private var viewModel = TVShowListViewModel()
    @State private var favoriteGenres: [MoviesGenre] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterRow

                Group {
                    if viewModel.isLoading, viewModel.shows.isEmpty {
                        ProgressView("Loading TV shows...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.isSearching, viewModel.displayedShows.isEmpty {
                        ProgressView("Searching TV shows...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.displayedShows.isEmpty {
                        ContentUnavailableView(emptyStateTitle, systemImage: "tv")
                    } else {
                        List(viewModel.displayedShows) { show in
                            NavigationLink {
                                TVShowDetailLoaderView(showID: show.id)
                            } label: {
                                TVShowRow(show: show)
                            }
                            .listRowSeparator(.hidden)
                            .task {
                                await viewModel.fetchNextPageIfNeeded(currentShow: show)
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
                            loadSavedIDs()
                        } label: {
                            Label("Watchlist", systemImage: viewModel.showSavedOnly ? "bookmark.fill" : "bookmark")
                        }

                        Button {
                            viewModel.isSorted.toggle()
                        } label: {
                            Label("Sort A-Z", systemImage: "arrow.up.arrow.down")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    LogoView()
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search TV shows")
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.scheduleSearch()
            }
        }
        .task {
            loadFavoriteGenres()
            if viewModel.shows.isEmpty {
                await viewModel.fetchAllShows()
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
        .onReceive(NotificationCenter.default.publisher(for: .tvShowLibraryDidChange)) { notification in
            guard notification.userInfo?["userID"] as? String == userID else { return }
            loadSavedIDs()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileFavoriteGenresDidChange)) { notification in
            guard notification.userInfo?["userID"] as? String == userID else { return }
            loadFavoriteGenres()
        }
    }

    private var navigationTitle: String {
        let title = switch viewModel.selectedFilter {
        case .all: "TV Shows"
        case .popular: "Popular TV Shows"
        case let .genre(genre): genre.displayName
        }
        return viewModel.showSavedOnly ? "Watchlist" : title
    }

    private var emptyStateTitle: String {
        if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No TV Shows Found"
        }

        let title = switch viewModel.selectedFilter {
        case .all: "TV Shows"
        case .popular: "Popular TV Shows"
        case let .genre(genre): "\(genre.displayName) TV Shows"
        }
        return viewModel.showSavedOnly ? "No Watchlist Items" : "No \(title) Found"
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton("All", filter: .all)
                filterButton("Popular", filter: .popular)
                ForEach(orderedGenres) { genre in
                    filterButton(genre.displayName, filter: .genre(genre))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private func filterButton(_ title: String, filter: TVShowListFilter) -> some View {
        let selected = viewModel.selectedFilter == filter
        return Button {
            guard !selected else { return }
            Task { await viewModel.selectFilter(filter) }
        } label: {
            Text(title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: 13))
                .foregroundStyle(selected ? .black : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? AppUI.ColorPalette.accent : AppUI.ColorPalette.secondarySurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func loadSavedIDs() {
        viewModel.savedIDs = TVShowLibraryService().showIDs(.saved, userID: userID)
    }

    private var orderedGenres: [TVGenre] {
        let favorites = favoriteGenres.flatMap { movieGenre in
            TVGenre.allCases.filter { $0.matches(movieGenre: movieGenre) }
        }
        let uniqueFavorites = favorites.reduce(into: [TVGenre]()) { result, genre in
            if !result.contains(genre) {
                result.append(genre)
            }
        }
        return uniqueFavorites + TVGenre.allCases.filter { !uniqueFavorites.contains($0) }
    }

    private func loadFavoriteGenres() {
        let stored = UserDefaults.standard.stringArray(
            forKey: ProfileUserDefaultsKeys.favoriteGenres(for: userID)
        ) ?? []
        favoriteGenres = stored.compactMap(MoviesGenre.fromStoredValue)
    }
}

private struct TVShowRow: View {
    let show: RemoteTVShow

    var body: some View {
        MediaListRow(
            title: show.name,
            posterPath: show.posterPath,
            primaryMetadata: firstAirYear,
            secondaryMetadata: nil,
            language: show.originalLanguage,
            genres: genreText,
            rating: show.voteAverage,
            ratingCount: show.voteCount
        )
    }

    private var firstAirYear: String {
        let year = String(show.firstAirDate.prefix(4))
        return year.isEmpty ? "TBA" : year
    }

    private var genreText: String {
        show.genreIDs.compactMap(TVGenre.name).prefix(3).joined(separator: ", ")
    }
}

#Preview {
    TVShowsListView(userID: "previewUser")
}
