import SwiftData
import SwiftUI

struct ActorListView: View {
    @State private var filterText = ""
    @State private var isLoading = false
    @State private var isSorted = false

    @State private var viewModel = ActorListViewModel()

    var filteredActors: [RemoteActor] {
        let baseList = filterText.isEmpty
            ? viewModel.actors
            : viewModel.actors.filter {
                $0.name.localizedCaseInsensitiveContains(filterText)
            }

        if isSorted {
            return baseList.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } else {
            return baseList
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else if filteredActors.isEmpty {
                    ContentUnavailableView("No Actors Found", systemImage: "person.crop.circle.badge.questionmark")
                } else {
                    List(filteredActors) { actor in
                        NavigationLink(actor.name) {
                            ActorDetailView(actor: actor)
                        }
                        .task {
                            await viewModel.fetchNextPageIfNeeded(currentActor: actor)
                        }
                    }
                }
            }
            .navigationTitle("Popular Actors")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSorted.toggle()
                    } label: {
                        Label("Sort A–Z", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LogoView()
                }
            }
        }
        .searchable(text: $filterText)
        .task {
            if viewModel.actors.isEmpty {
                await loadActors()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func loadActors() async {
        isLoading = true
        await viewModel.fetchPopularActors()
        isLoading = false
    }
}

#Preview {
    ActorListView()
}
