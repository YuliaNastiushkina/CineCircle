import SwiftUI

struct ActorDetailView: View {
    let actorID: Int
    let actorName: String
    let profilePath: String?
    let knownForTitles: [String]

    init(actor: RemoteActor) {
        actorID = actor.id
        actorName = actor.name
        profilePath = actor.profilePath
        knownForTitles = actor.knownFor.compactMap { $0.title ?? $0.name }
    }

    init(actor: MovieCast) {
        actorID = actor.id
        actorName = actor.name
        profilePath = actor.profilePath
        knownForTitles = []
    }

    var body: some View {
        PersonDetailContentView(
            name: actorName,
            role: nil,
            profilePath: profilePath,
            knownForTitles: knownForTitles,
            viewModel: viewModel
        )
        .task {
            await viewModel.fetchActorDetails(for: actorID)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @State private var viewModel = ActorDetailsViewModel()
}

#Preview {
    NavigationStack {
        let sampleActor: RemoteActor = .init(
            id: 1,
            name: "Pedro Pascal",
            knownFor: [
                KnownForItem(id: 1, title: "The Last of Us", name: nil),
                KnownForItem(id: 2, title: "The Mandalorian", name: nil),
                KnownForItem(id: 3, title: "Narcos", name: nil),
            ],
            profilePath: nil
        )
        ActorDetailView(actor: sampleActor)
    }
}
