import SwiftUI
import SwiftData

struct MovieDetail: View {
    @Bindable var movie: Movie
    let isNew: Bool
    
    init(movie: Movie, isNew: Bool = false) {
        self.movie = movie
        self.isNew = isNew
    }
    
    var sortedFriends: [Friend] {
        movie.favoritedBy.sorted { first, second in
            first.name < second.name
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    var body: some View {
        Form {
            TextField("Title", text: $movie.title)
            DatePicker("Release Date", selection: $movie.releaseDate,  displayedComponents: .date)
            
            if !movie.favoritedBy.isEmpty {
                Section("Favorited by") {
                    ForEach(sortedFriends) { friend in
                        Text(friend.name)
                    }
                    .onDelete(perform: deleteFriend)
                }
            }
            
            if !movie.cast.isEmpty {
                Section("Cast") {
                    ForEach(movie.cast) { member in
                        Text(member.actorName)
                    }
                }

            }
        }
        .navigationTitle(isNew ? "New movie" : "Movie's Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(movie)
                        dismiss()
                    }
                }
            }
        }
    }
    
    //MARK: Private interface
    private func deleteFriend(indexes: IndexSet) {
        for index in indexes {
            context.delete(movie.favoritedBy[index])
        }
    }
}

#Preview {
    NavigationStack {
        MovieDetail(movie: SampleData.shared.movie)
    }
    .modelContainer(SampleData.shared.modelContainer)
}
