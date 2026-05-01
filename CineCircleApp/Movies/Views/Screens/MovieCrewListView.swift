import SwiftUI

struct MovieCrewListView: View {
    let crew: [MovieCrew]

    var body: some View {
        MoviePeopleGridView(title: "Crew", items: crew)
    }
}

#Preview {
    NavigationStack {
        MovieCrewListView(crew: [
            MovieCrew(id: 1, name: "Sample Director", job: "Director, Writer", profilePath: nil),
            MovieCrew(id: 2, name: "Sample Producer", job: "Producer", profilePath: nil),
        ])
    }
}
