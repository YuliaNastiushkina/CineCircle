import SwiftData
import SwiftUI

struct MoviesList: View {
    @State private var filterText = ""
    @State private var isLoading = false
    @State private var isSorted = false

    @State private var viewModel = MovieListViewModel()

    var filteredMovies: [RemoteMovie] {
        let baseList = filterText.isEmpty
            ? viewModel.movies
            : viewModel.movies.filter {
                $0.title.localizedCaseInsensitiveContains(filterText)
            }

        if isSorted {
            return baseList.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        } else {
            return baseList
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else if filteredMovies.isEmpty {
                    ContentUnavailableView("No Movies Found", systemImage: "film.stack")
                } else {
                    List(filteredMovies) { movie in
                        NavigationLink(movie.title) {
                            Text("Here will be \(movie.title) details")
                        }
                    }
                }
            }
            .navigationTitle("Popular Movies")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSorted.toggle()
                    } label: {
                        Label("Sort A–Z", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .searchable(text: $filterText)
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
    }

    private func loadMovies() async {
        isLoading = true
        await viewModel.fetchPopularMovies()
        isLoading = false
    }
}

#Preview {
    MoviesList()
}
