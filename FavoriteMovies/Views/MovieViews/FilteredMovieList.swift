import SwiftUI

struct FilteredMovieList: View {
    @State private var searchText: String = ""
    @State var isFilteredByReleaseDate: Bool = false

    var body: some View {
        NavigationSplitView {
            MoviesList(filterText: searchText, sortBy: isFilteredByReleaseDate ? .releaseDate : .title)
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Toggle("Sort by release date", isOn: $isFilteredByReleaseDate)
                            .toggleStyle(.switch)
                            .font(.headline)
                    }
                }
        } detail: {
            Text("Select a movie")
                .navigationTitle("Movie")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FilteredMovieList()
        .modelContainer(SampleData.shared.modelContainer)
}
