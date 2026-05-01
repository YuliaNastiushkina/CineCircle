import SwiftUI

private enum MoviePeopleGridParameters {
    static let spacing: CGFloat = 16
    static let columnCount = 3
}

protocol MoviePersonDisplayable: Identifiable {
    var personID: Int { get }
    var name: String { get }
    var roleText: String? { get }
    var profilePath: String? { get }
}

extension MovieCast: MoviePersonDisplayable {
    var personID: Int { id }
    var roleText: String? { nil }
}

extension MovieCrew: MoviePersonDisplayable {
    var personID: Int { id }
    var roleText: String? { job }
}

struct MoviePeopleGridView<Item: MoviePersonDisplayable>: View {
    let title: String
    let items: [Item]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: MoviePeopleGridParameters.spacing) {
                ForEach(items) { item in
                    NavigationLink {
                        CrewPersonDetailView(
                            personID: item.personID,
                            name: item.name,
                            role: item.roleText,
                            profilePath: item.profilePath
                        )
                    } label: {
                        PersonChipView(
                            name: item.name,
                            role: item.roleText,
                            profilePath: item.profilePath,
                            nameLineLimit: 2
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: MoviePeopleGridParameters.spacing, alignment: .top),
            count: MoviePeopleGridParameters.columnCount
        )
    }
}

#Preview {
    NavigationStack {
        MoviePeopleGridView(
            title: "Cast",
            items: [
                MovieCast(id: 1, name: "Sample Actor", profilePath: nil),
                MovieCast(id: 2, name: "Another Actor", profilePath: nil),
            ]
        )
    }
}
