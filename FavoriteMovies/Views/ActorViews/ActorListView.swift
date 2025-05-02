import SwiftUI
import SwiftData

struct ActorListView: View {
    @Query(sort: \CastMember.actorName) private var actors: [CastMember]
    @State var newActor: CastMember?
    @Environment(\.modelContext) private var context
    
    var body: some View {
        Group {
            if !actors.isEmpty {
                List {
                    ForEach(actors) { castMember in
                        NavigationLink(castMember.actorName) {
                            ActorDetailView(castMember: castMember)
                        }
                    }
                    .onDelete(perform: deleteActor)
                }
            } else {
                ContentUnavailableView("Add an actor", systemImage: "person.crop.rectangle.stack.fill")
            }
        }
        .navigationTitle("Actors")
        .toolbar {
            ToolbarItem {
                Button("Add actor", systemImage: "plus", action: addActor)
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $newActor) { castMember in
            NavigationStack {
                ActorDetailView(castMember: castMember, isNew: true)
            }
            .interactiveDismissDisabled()
        }
    }
    
    //MARK: Private interface
    private func addActor() {
        let newActor = CastMember(actorName: "")
        context.insert(newActor)
        self.newActor = newActor
    }
    
    private func deleteActor(indexes: IndexSet) {
        for index in indexes {
            context.delete(actors[index])
        }
    }
}

#Preview {
    NavigationStack {
        ActorListView()
            .modelContainer(SampleData.shared.modelContainer)
    }
}

#Preview("Empty List") {
    NavigationStack {
        ActorListView()
            .modelContainer(for: CastMember.self, inMemory: true)
    }
}
