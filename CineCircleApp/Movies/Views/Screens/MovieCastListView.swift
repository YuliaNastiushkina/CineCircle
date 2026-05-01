import SwiftUI

struct MovieCastListView: View {
    let cast: [MovieCast]

    var body: some View {
        MoviePeopleGridView(title: "Cast", items: cast)
    }
}

#Preview {
    NavigationStack {
        MovieCastListView(cast: [
            MovieCast(id: 1, name: "Sample Actor", profilePath: nil),
            MovieCast(id: 2, name: "Another Actor", profilePath: nil),
        ])
    }
}
