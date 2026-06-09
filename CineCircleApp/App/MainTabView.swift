import SwiftUI

struct MainTabView: View {
    let userId: String

    init(userId: String) {
        self.userId = userId

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)

        let selectedColor = UIColor(AppUI.ColorPalette.accent)
        let normalColor = UIColor.darkGray

        [appearance.stackedLayoutAppearance,
         appearance.inlineLayoutAppearance,
         appearance.compactInlineLayoutAppearance].forEach { itemAppearance in
            itemAppearance.normal.iconColor = normalColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            MoviesListView(userId: userId)
                .tabItem {
                    Label("Movies", systemImage: "film.stack")
                }

            ActorListView()
                .tabItem {
                    Label("Actors", systemImage: "video")
                }

            ProfileView(userId: userId)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.square")
                }
        }
        .tint(AppUI.ColorPalette.accent)
    }
}

#Preview {
    MainTabView(userId: "123a")
}
