import SwiftUI

struct CrewPersonDetailView: View {
    let personID: Int
    let name: String
    let role: String?
    let profilePath: String?

    var body: some View {
        PersonDetailContentView(
            name: name,
            role: role,
            profilePath: profilePath,
            knownForTitles: [],
            viewModel: viewModel
        )
        .task {
            await viewModel.fetchActorDetails(for: personID)
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
        CrewPersonDetailView(
            personID: 1,
            name: "Sample Person",
            role: "Director",
            profilePath: nil
        )
    }
}
