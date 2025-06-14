import SwiftUI

struct MainView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        TabView {
            Tab("Movies", systemImage: "film.stack") {
                MoviesListView()
            }

            Tab("Actors", systemImage: "person.crop.square.badge.video.fill") {
                ActorListView()
            }

            Tab("Profile", systemImage: "person.crop.circle") {
                if let userId = authService.currentUserId {
                    ProfileView(userId: userId)
                }
            }
        }
    }
}

#Preview {
    MainView()
}
