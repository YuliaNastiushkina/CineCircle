import CoreData
import SwiftUI

struct MoviesListView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var userSession: UserSession

    let userId: String

    @State private var viewModel = MovieListViewModel()
    @State private var favoriteGenres: [MoviesGenre] = []
    @FocusState private var isAIPromptFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if viewModel.isAIMode {
                        aiSuggestionFilter
                            .id(MoviesListLayout.aiSuggestionFilterID)
                            .transition(aiSuggestionFilterTransition)
                    } else {
                        genreFilter
                            .id(MoviesListLayout.genreFilterID)
                            .transition(genreFilterTransition)
                    }
                }

                MovieSearchControls(
                    viewModel: viewModel,
                    isAIPromptFocused: $isAIPromptFocused,
                    submitAIRecommendationPrompt: submitAIRecommendationPrompt
                )
                AIStatusMessageView(message: viewModel.recommendationErrorMessage)
                AIResultsHeaderView(
                    viewModel: viewModel,
                    clearAction: viewModel.clearAIRecommendations
                )

                movieListContent
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarActions
                }

                ToolbarItem(placement: .topBarTrailing) {
                    LogoView()
                }
            }
        }
        .animation(.easeInOut(duration: MoviesListLayout.modeTransitionDuration), value: viewModel.isAIMode)
        .animation(.easeInOut(duration: MoviesListLayout.titleTransitionDuration), value: navigationTitle)
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

    private var navigationTitle: String {
        if viewModel.isAIMode {
            return "AI Picks"
        }

        let title: String = switch viewModel.selectedFilter {
        case .all: "Movies"
        case .popular: "Popular Movies"
        case let .genre(genre): genre.displayName
        }
        return viewModel.showSavedOnly ? "Watchlist" : title
    }

    private var emptyStateTitle: String {
        if viewModel.isAIMode {
            return viewModel.aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "What should we find?"
                : "No AI Matches Found"
        }

        if !viewModel.filterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No Movies Found"
        }

        let title = switch viewModel.selectedFilter {
        case .all: "Movies"
        case .popular: "Popular Movies"
        case let .genre(genre): "\(genre.displayName) Movies"
        }
        return viewModel.showSavedOnly ? "No Watchlist Items" : "No \(title) Found"
    }

    private var orderedGenres: [MoviesGenre] {
        favoriteGenres + MoviesGenre.allCases.filter { !favoriteGenres.contains($0) }
    }

    private var genreFilterTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var aiSuggestionFilterTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    @ViewBuilder private var movieListContent: some View {
        if viewModel.isLoadingRecommendations, viewModel.displayedMovies.isEmpty {
            fullScreenLoadingContent {
                AILoadingView()
            }
        } else if viewModel.isLoading, viewModel.movies.isEmpty {
            fullScreenLoadingContent {
                ProgressView("Loading...")
            }
        } else if viewModel.isSearching, viewModel.displayedMovies.isEmpty {
            fullScreenLoadingContent {
                ProgressView("Searching...")
            }
        } else if viewModel.displayedMovies.isEmpty {
            ContentUnavailableView(emptyStateTitle, systemImage: "film.stack")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).onTapGesture(perform: dismissKeyboard))
        } else {
            movieResultsList
        }
    }

    private var movieResultsList: some View {
        ScrollViewReader { scrollProxy in
            List {
                ForEach(viewModel.displayedMovies, id: \.id) { movie in
                    NavigationLink {
                        MovieDetailViewLoaderView(movieID: movie.id)
                    } label: {
                        MovieListRow(movie: movie)
                    }
                    .id(movie.id)
                    .listRowSeparator(.hidden)
                    .task {
                        if !viewModel.isAIMode {
                            await viewModel.fetchNextPageIfNeeded(currentMovie: movie)
                        }
                    }
                }

                if viewModel.isAIMode {
                    AIPaginationControlsView(
                        viewModel: viewModel,
                        showPreviousAction: {
                            viewModel.showPreviousRecommendations()
                            scrollToFirstVisibleRecommendation(using: scrollProxy)
                        },
                        showNextAction: {
                            viewModel.showNextRecommendations()
                            scrollToFirstVisibleRecommendation(using: scrollProxy)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground).onTapGesture(perform: dismissKeyboard))
            .scrollDismissesKeyboard(.immediately)
        }
    }

    private var toolbarActions: some View {
        HStack {
            Button {
                if viewModel.isAIMode {
                    viewModel.exitAIMode()
                }
                viewModel.showSavedOnly.toggle()
                if viewModel.showSavedOnly { loadSavedIDs() }
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

    private var genreFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MoviesListLayout.filterSpacing) {
                filterButton(title: MoviesListLayout.filterAll, filter: .all)
                filterButton(title: MoviesListLayout.filterPopular, filter: .popular)

                ForEach(orderedGenres) { genre in
                    filterButton(title: genre.displayName, filter: .genre(genre))
                }
            }
            .padding(.horizontal, MoviesListLayout.filterHorizontalPadding)
            .padding(.vertical, MoviesListLayout.filterVerticalPadding)
        }
        .background(Color(.systemBackground))
    }

    private var aiSuggestionFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MoviesListLayout.filterSpacing) {
                ForEach(viewModel.aiSuggestionPrompts, id: \.self) { prompt in
                    Button {
                        viewModel.aiPromptText = prompt
                        isAIPromptFocused = false
                        submitAIRecommendationPrompt()
                    } label: {
                        Text(prompt)
                            .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.filterFontSize))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, MoviesListLayout.filterHorizontalChipPadding)
                            .padding(.vertical, MoviesListLayout.filterVerticalChipPadding)
                            .background(AppUI.ColorPalette.secondarySurface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, MoviesListLayout.filterHorizontalPadding)
            .padding(.vertical, MoviesListLayout.filterVerticalPadding)
        }
        .background(Color(.systemBackground))
    }

    private func filterButton(title: String, filter: MovieListFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter

        return Button {
            if viewModel.isAIMode {
                viewModel.exitAIMode()
            }
            guard viewModel.selectedFilter != filter else { return }
            Task {
                await viewModel.selectFilter(filter)
            }
        } label: {
            Text(title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: MoviesListLayout.filterFontSize))
                .foregroundColor(isSelected ? .black : .primary)
                .padding(.horizontal, MoviesListLayout.filterHorizontalChipPadding)
                .padding(.vertical, MoviesListLayout.filterVerticalChipPadding)
                .background(isSelected ? AppUI.ColorPalette.accent : AppUI.ColorPalette.secondarySurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func fullScreenLoadingContent(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground).onTapGesture(perform: dismissKeyboard))
    }

    private func submitAIRecommendationPrompt() {
        guard !viewModel.aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        Task {
            await viewModel.submitAIRecommendationPrompt()
        }
    }

    private func scrollToFirstVisibleRecommendation(using scrollProxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            guard let firstMovieID = viewModel.visibleRecommendationMovies.first?.id else { return }
            withAnimation(.easeInOut(duration: MoviesListLayout.recommendationScrollDuration)) {
                scrollProxy.scrollTo(firstMovieID, anchor: .top)
            }
        }
    }

    private func dismissKeyboard() {
        isAIPromptFocused = false
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

#Preview {
    MoviesListView(userId: "previewUser")
        .environmentObject(UserSession())
}
