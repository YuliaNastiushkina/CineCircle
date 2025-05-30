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

            Tab("Settings", systemImage: "gearshape.fill") {
                Button("Sign out") {
                    authService.signOut()
                }
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(SampleData.shared.modelContainer)
}
