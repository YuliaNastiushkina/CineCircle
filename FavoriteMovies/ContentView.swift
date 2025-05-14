import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Friends", systemImage: "person.and.person") {
                FilteredFriendList()
            }

            Tab("Movies", systemImage: "film.stack") {
                MoviesList()
            }

            Tab("Actors", systemImage: "person.crop.square.badge.video.fill") {
                ActorListView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
