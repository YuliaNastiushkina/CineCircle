import SwiftUI

struct ActorCreditsListView: View {
    let actorName: String
    let credits: [ActorCredit]

    @State private var searchText = ""

    var body: some View {
        Group {
            if filteredCredits.isEmpty {
                ContentUnavailableView(emptyTitle, systemImage: "film.stack")
            } else {
                List(filteredCredits) { credit in
                    NavigationLink {
                        creditDestination(for: credit)
                    } label: {
                        PersonCreditRow(credit: credit, showsChevron: false)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("\(actorName)'s Movies & TV")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search movies and TV")
    }

    private var filteredCredits: [ActorCredit] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return credits }

        return credits.filter { credit in
            credit.displayTitle.localizedCaseInsensitiveContains(query)
                || (credit.character?.localizedCaseInsensitiveContains(query) ?? false)
                || credit.mediaLabel.localizedCaseInsensitiveContains(query)
                || credit.displayYear.localizedCaseInsensitiveContains(query)
        }
    }

    private var emptyTitle: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "No Credits Found"
            : "No Matching Credits"
    }

    @ViewBuilder private func creditDestination(for credit: ActorCredit) -> some View {
        if credit.mediaType == ActorCredit.tvMediaType {
            TVShowDetailLoaderView(showID: credit.tmdbID)
        } else {
            MovieDetailViewLoaderView(movieID: credit.tmdbID)
        }
    }
}

#Preview {
    NavigationStack {
        ActorCreditsListView(actorName: "Sample Actor", credits: [])
    }
}
