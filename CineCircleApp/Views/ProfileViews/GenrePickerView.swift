import SwiftUI

struct GenrePickerView: View {
    @Binding var selectedGenres: [MoviesGenre]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(MoviesGenre.allCases, id: \.self) { genre in
                    MultipleSelectionRow(
                        title: genre.rawValue.capitalized,
                        isSelected: selectedGenres.contains(genre)
                    ) {
                        if selectedGenres.contains(genre) {
                            selectedGenres.removeAll { $0 == genre }
                        } else {
                            selectedGenres.append(genre)
                        }
                    }
                }
            }
            .navigationTitle("Select Genres")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GenrePickerView(selectedGenres: .constant([.crime, .action]))
}
