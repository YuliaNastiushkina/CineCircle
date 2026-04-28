import SwiftUI

struct MainTabView: View {
    let userId: String

    var body: some View {
        TabView {
            MoviesListView()
                .tabItem {
                    Label("Movies", systemImage: "film.stack")
                }

            ActorListView()
                .tabItem {
                    Label("Actors", systemImage: "person.crop.square.badge.video.fill")
                }

            ProfileView(userId: userId)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    MainTabView(userId: "123a")
}
