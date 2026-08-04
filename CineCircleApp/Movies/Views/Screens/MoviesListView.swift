import CoreData
import SwiftData
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
                genreFilter
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

                Group {
                    if viewModel.isLoadingRecommendations, viewModel.displayedMovies.isEmpty {
                        AILoadingView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground).onTapGesture(perform: dismissKeyboard))
                    } else if viewModel.isLoading, viewModel.movies.isEmpty {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground).onTapGesture(perform: dismissKeyboard))
                    } else if viewModel.isSearching, viewModel.displayedMovies.isEmpty {
                        ProgressView("Searching...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground).onTapGesture(perform: dismissKeyboard))
                    } else if viewModel.displayedMovies.isEmpty {
                        ContentUnavailableView(emptyStateTitle, systemImage: "film.stack")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground).onTapGesture(perform: dismissKeyboard))
                    } else {
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
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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

                ToolbarItem(placement: .topBarTrailing) {
                    LogoView()
                }
            }
        }
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

private struct MovieSearchControls: View {
    @Bindable var viewModel: MovieListViewModel
    let isAIPromptFocused: FocusState<Bool>.Binding

    let submitAIRecommendationPrompt: () -> Void

    var body: some View {
        VStack(spacing: MoviesListLayout.searchVerticalSpacing) {
            if viewModel.isAIMode {
                aiPromptBar
                aiSuggestionChips
            } else {
                normalSearchBar
            }
        }
        .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
        .padding(.bottom, MoviesListLayout.searchBottomPadding)
        .background(Color(.systemBackground))
    }

    private var normalSearchBar: some View {
        HStack(spacing: MoviesListLayout.searchControlSpacing) {
            HStack(spacing: MoviesListLayout.searchIconSpacing) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search movies", text: $viewModel.filterText)
                    .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.searchFontSize))
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.scheduleSearch()
                    }
            }
            .padding(.horizontal, MoviesListLayout.searchFieldHorizontalPadding)
            .frame(height: MoviesListLayout.searchFieldHeight)
            .background(AppUI.ColorPalette.secondarySurface)
            .clipShape(Capsule())

            Button {
                viewModel.enterAIMode()
            } label: {
                Label("AI", systemImage: "sparkles")
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: MoviesListLayout.aiButtonFontSize))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.black)
                    .padding(.horizontal, MoviesListLayout.aiButtonHorizontalPadding)
                    .frame(height: MoviesListLayout.searchFieldHeight)
                    .background(AppUI.ColorPalette.accent, in: Capsule())
                    .overlay {
                        Capsule()
                            .fill(aiGlassHighlight)
                    }
                    .overlay {
                        Capsule()
                            .stroke(aiAccentStroke, lineWidth: MoviesListLayout.aiControlStrokeWidth)
                    }
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    private var aiPromptBar: some View {
        HStack(alignment: .bottom, spacing: MoviesListLayout.searchControlSpacing) {
            HStack(alignment: .top, spacing: MoviesListLayout.searchIconSpacing) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppUI.ColorPalette.accent)
                    .padding(.top, MoviesListLayout.aiPromptIconTopPadding)

                TextField("Describe the movie you want", text: $viewModel.aiPromptText, axis: .vertical)
                    .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.searchFontSize))
                    .lineLimit(1...4)
                    .submitLabel(.search)
                    .focused(isAIPromptFocused)
                    .disabled(viewModel.isLoadingRecommendations)
                    .onSubmit(submitPromptAndDismissKeyboard)
            }
            .padding(.horizontal, MoviesListLayout.searchFieldHorizontalPadding)
            .padding(.vertical, MoviesListLayout.aiPromptVerticalPadding)
            .frame(minHeight: MoviesListLayout.searchFieldHeight)
            .background(AppUI.ColorPalette.secondarySurface, in: RoundedRectangle(cornerRadius: MoviesListLayout.aiPromptCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MoviesListLayout.aiPromptCornerRadius, style: .continuous)
                    .stroke(AppUI.ColorPalette.accent, lineWidth: MoviesListLayout.aiPromptStrokeWidth)
            }
            .shadow(color: AppUI.ColorPalette.accent.opacity(0.14), radius: 3, x: 0, y: 1)

            Button(action: submitPromptAndDismissKeyboard) {
                Image(systemName: viewModel.isLoadingRecommendations ? "hourglass" : "paperplane.fill")
                    .font(.system(size: MoviesListLayout.aiIconButtonSize, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: MoviesListLayout.aiIconButtonFrame, height: MoviesListLayout.aiIconButtonFrame)
                    .background(AppUI.ColorPalette.accent, in: Circle())
                    .overlay {
                        Circle()
                            .fill(aiGlassHighlight)
                    }
                    .overlay {
                        Circle()
                            .stroke(aiAccentStroke, lineWidth: MoviesListLayout.aiControlStrokeWidth)
                    }
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingRecommendations || viewModel.aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button {
                isAIPromptFocused.wrappedValue = false
                viewModel.exitAIMode()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: MoviesListLayout.aiIconButtonSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: MoviesListLayout.aiIconButtonFrame, height: MoviesListLayout.aiIconButtonFrame)
                    .background(AppUI.ColorPalette.secondarySurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var aiSuggestionChips: some View {
        if viewModel.visibleRecommendationMovies.isEmpty, !viewModel.isLoadingRecommendations {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MoviesListLayout.aiSuggestionSpacing) {
                    ForEach(MoviesListLayout.aiSuggestionPrompts, id: \.self) { prompt in
                        Button {
                            viewModel.aiPromptText = prompt
                            submitPromptAndDismissKeyboard()
                        } label: {
                            Text(prompt)
                                .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.aiSuggestionFontSize))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, MoviesListLayout.aiSuggestionHorizontalPadding)
                                .padding(.vertical, MoviesListLayout.aiSuggestionVerticalPadding)
                                .background(AppUI.ColorPalette.secondarySurface)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var aiAccentStroke: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.78),
                AppUI.ColorPalette.accent.opacity(0.85),
                .white.opacity(0.32),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var aiGlassHighlight: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.38),
                .white.opacity(0.12),
                .clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func submitPromptAndDismissKeyboard() {
        isAIPromptFocused.wrappedValue = false
        submitAIRecommendationPrompt()
    }
}

private struct AIStatusMessageView: View {
    let message: String?

    var body: some View {
        if let message {
            HStack(spacing: MoviesListLayout.statusMessageSpacing) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.statusMessageFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
            .padding(.bottom, MoviesListLayout.statusMessageBottomPadding)
            .background(Color(.systemBackground))
        }
    }
}

private struct AILoadingView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: MoviesListLayout.aiLoadingSpacing) {
            ZStack {
                Circle()
                    .fill(AppUI.ColorPalette.accent.opacity(0.22))
                    .frame(width: MoviesListLayout.aiLoadingOuterCircle, height: MoviesListLayout.aiLoadingOuterCircle)
                    .scaleEffect(pulse ? 1.14 : 0.92)

                Image(systemName: "sparkles")
                    .font(.system(size: MoviesListLayout.aiLoadingIconSize, weight: .semibold))
                    .foregroundStyle(AppUI.ColorPalette.accent)
            }

            Text("Thinking through your request")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: MoviesListLayout.aiLoadingTitleFontSize))

            Text("Comparing themes, mood, and popularity")
                .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.aiLoadingSubtitleFontSize))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct AIResultsHeaderView: View {
    let viewModel: MovieListViewModel
    let clearAction: () -> Void

    var body: some View {
        if viewModel.isAIMode, !viewModel.rankedRecommendationMovies.isEmpty {
            VStack(alignment: .leading, spacing: MoviesListLayout.resultsHeaderSpacing) {
                HStack {
                    Label("AI Picks", systemImage: "sparkles")
                        .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: MoviesListLayout.resultsTitleFontSize))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button(action: clearAction) {
                        Label("Clear", systemImage: "trash")
                            .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.resultsActionFontSize))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                if let explanation = viewModel.recommendationExplanation {
                    Text(explanation)
                        .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.resultsExplanationFontSize))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
            .padding(.bottom, MoviesListLayout.resultsHeaderBottomPadding)
            .background(Color(.systemBackground))
        }
    }
}

private struct AIPaginationControlsView: View {
    let viewModel: MovieListViewModel
    let showPreviousAction: () -> Void
    let showNextAction: () -> Void

    var body: some View {
        if viewModel.canShowNextRecommendations || viewModel.canShowPreviousRecommendations || viewModel.shouldSuggestRefiningAIRequest {
            VStack(spacing: MoviesListLayout.paginationVerticalSpacing) {
                HStack(spacing: MoviesListLayout.paginationSpacing) {
                    if viewModel.canShowPreviousRecommendations {
                        Button(action: showPreviousAction) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: MoviesListLayout.paginationIconSize, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: MoviesListLayout.paginationIconFrame, height: MoviesListLayout.paginationIconFrame)
                                .background(AppUI.ColorPalette.secondarySurface, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.canShowNextRecommendations {
                        Button(action: showNextAction) {
                            Label("Show others", systemImage: "sparkles")
                                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: MoviesListLayout.paginationFontSize))
                                .foregroundStyle(.black)
                                .padding(.horizontal, MoviesListLayout.paginationHorizontalPadding)
                                .frame(height: MoviesListLayout.paginationButtonHeight)
                                .background(AppUI.ColorPalette.accent, in: Capsule())
                                .overlay {
                                    Capsule()
                                        .fill(aiGlassHighlight)
                                }
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.78),
                                                    AppUI.ColorPalette.accent,
                                                    .white.opacity(0.3),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: MoviesListLayout.aiControlStrokeWidth
                                        )
                                }
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if viewModel.shouldSuggestRefiningAIRequest {
                    Text("Try adding more detail to get closer picks.")
                        .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.paginationHintFontSize))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
            .padding(.vertical, MoviesListLayout.paginationVerticalPadding)
            .background(Color(.systemBackground))
        }
    }

    private var aiGlassHighlight: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.38),
                .white.opacity(0.12),
                .clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

private enum MoviesListLayout {
    static let filterAll = "All"
    static let filterPopular = "Popular"
    static let filterSpacing: CGFloat = 8
    static let filterHorizontalPadding: CGFloat = 16
    static let filterVerticalPadding: CGFloat = 10
    static let filterFontSize: CGFloat = 13
    static let filterHorizontalChipPadding: CGFloat = 14
    static let filterVerticalChipPadding: CGFloat = 8

    static let searchHorizontalPadding: CGFloat = 16
    static let searchBottomPadding: CGFloat = 10
    static let searchVerticalSpacing: CGFloat = 8
    static let searchControlSpacing: CGFloat = 8
    static let searchIconSpacing: CGFloat = 8
    static let searchFieldHeight: CGFloat = 42
    static let searchFieldHorizontalPadding: CGFloat = 14
    static let searchFontSize: CGFloat = 14

    static let aiPromptVerticalPadding: CGFloat = 11
    static let aiPromptIconTopPadding: CGFloat = 2
    static let aiPromptCornerRadius: CGFloat = 20
    static let aiPromptStrokeWidth: CGFloat = 1.25
    static let aiButtonFontSize: CGFloat = 13
    static let aiButtonHorizontalPadding: CGFloat = 14
    static let aiIconButtonSize: CGFloat = 14
    static let aiIconButtonFrame: CGFloat = 42
    static let aiControlStrokeWidth: CGFloat = 1
    static let aiSuggestionSpacing: CGFloat = 8
    static let aiSuggestionFontSize: CGFloat = 12
    static let aiSuggestionHorizontalPadding: CGFloat = 12
    static let aiSuggestionVerticalPadding: CGFloat = 7
    static let aiSuggestionPrompts = [
        "Comedy treasure adventure",
        "Feel-good after breakup",
        "Dark mystery with great acting",
    ]

    static let statusMessageSpacing: CGFloat = 8
    static let statusMessageFontSize: CGFloat = 12
    static let statusMessageBottomPadding: CGFloat = 8

    static let aiLoadingSpacing: CGFloat = 10
    static let aiLoadingOuterCircle: CGFloat = 64
    static let aiLoadingIconSize: CGFloat = 24
    static let aiLoadingTitleFontSize: CGFloat = 16
    static let aiLoadingSubtitleFontSize: CGFloat = 12

    static let resultsHeaderSpacing: CGFloat = 4
    static let resultsTitleFontSize: CGFloat = 16
    static let resultsActionFontSize: CGFloat = 12
    static let resultsExplanationFontSize: CGFloat = 12
    static let resultsHeaderBottomPadding: CGFloat = 8

    static let recommendationScrollDuration = 0.25
    static let paginationSpacing: CGFloat = 8
    static let paginationVerticalSpacing: CGFloat = 6
    static let paginationFontSize: CGFloat = 12
    static let paginationHintFontSize: CGFloat = 11
    static let paginationIconSize: CGFloat = 13
    static let paginationIconFrame: CGFloat = 34
    static let paginationButtonHeight: CGFloat = 36
    static let paginationHorizontalPadding: CGFloat = 16
    static let paginationVerticalPadding: CGFloat = 8
}

#Preview {
    MoviesListView(userId: "previewUser")
        .environmentObject(UserSession())
}
