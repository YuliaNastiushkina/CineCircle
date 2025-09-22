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
                        NavigationLink(movie.title) {
                            MovieDetailViewLoaderView(movieID: movie.id)
                        }
                        .task {
                            if movie.id == viewModel.movies.last?.id {
                                await viewModel.fetchNextPageIfNeeded(currentMovie: movie)
                            }
                        }
                    }
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

#Preview {
    MoviesListView()
        .environmentObject(UserSession())
}
