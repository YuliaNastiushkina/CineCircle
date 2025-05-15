import SwiftUI

struct ContentView: View {
    @State private var isLoaded = true

    var body: some View {
        TabView {
            Tab("Friends", systemImage: "person.and.person") {
                FilteredFriendList()
            }

            Tab("Movies", systemImage: "film.stack") {
                MoviesListView()
            }

            Tab("Actors", systemImage: "person.crop.square.badge.video.fill") {
                ActorListView()
            }
        }
        .opacity(isLoaded ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: isLoaded)
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
