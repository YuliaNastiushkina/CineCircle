import SwiftData
import SwiftUI

struct MoviesList: View {
    @Environment(\.modelContext) private var context

    @Query private var movies: [Movie]
    @State var newMovie: Movie?

    init(filterText: String = "", sortBy: MovieSortOption = .title) {
        let predicate = #Predicate<Movie> { movie in
            filterText.isEmpty ||
                movie.title.localizedStandardContains(filterText) ||
                movie.cast.contains { member in
                    member.actorName.localizedStandardContains(filterText)
                }
        }

        _movies = Query(filter: predicate, sort: [sortBy.sortDescriptor])
    }

    var body: some View {
        Group {
            if !movies.isEmpty {
                List {
                    ForEach(movies) { movie in
                        NavigationLink(movie.title) {
                            MovieDetail(movie: movie)
                        }
                    }
                    .onDelete(perform: deleteMovie(indexes:))
                }
            } else {
                ContentUnavailableView("Add Movies", systemImage: "film.stack")
            }
        }
        .navigationTitle("Movies")
        .toolbar {
            ToolbarItem {
                Button("Add movie", systemImage: "plus", action: addMovie)
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $newMovie) { movie in
            NavigationStack {
                MovieDetail(movie: movie, isNew: true)
            }
            .interactiveDismissDisabled()
        }
    }

    // MARK: Private interface

    private func addMovie() {
        let newMovie = Movie(title: "", releaseDate: .now)
        context.insert(newMovie)
        self.newMovie = newMovie
    }

    private func deleteMovie(indexes: IndexSet) {
        for index in indexes {
            context.delete(movies[index])
        }
    }
}

#Preview {
    NavigationStack {
        MoviesList()
            .modelContainer(SampleData.shared.modelContainer)
    }
}

#Preview("Filtered") {
    NavigationStack {
        MoviesList(filterText: "tr")
            .modelContainer(SampleData.shared.modelContainer)
    }
}

#Preview("Empty List") {
    NavigationStack {
        MoviesList()
            .modelContainer(for: Movie.self, inMemory: true)
    }
}
