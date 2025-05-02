import SwiftData
import SwiftUI

struct ActorDetailView: View {
    @Bindable var castMember: CastMember
    @State var isNew: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    init(castMember: CastMember, isNew: Bool = false) {
        self.castMember = castMember
        self.isNew = isNew
    }

    var body: some View {
        Form {
            TextField("Actor name", text: $castMember.actorName)

            if !castMember.movies.isEmpty {
                Section("Movies") {
                    ForEach(castMember.movies) { movie in
                        Text(movie.title)
                    }
                    .onDelete(perform: deleteMovie)
                }
            }
        }
        .navigationTitle(isNew ? "New actor" : "\(castMember.actorName)'s details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    context.delete(castMember)
                    dismiss()
                }
            }
        }
    }

    // MARK: Private interface

    private func deleteMovie(indexes: IndexSet) {
        for index in indexes {
            context.delete(castMember.movies[index])
        }
    }
}

#Preview {
    ActorDetailView(castMember: SampleData.shared.castMember)
        .modelContainer(SampleData.shared.modelContainer)
}
