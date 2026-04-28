import SwiftUI

struct GenrePickerView: View {
    @Binding var selectedGenres: [MoviesGenre]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(MoviesGenre.allCases, id: \.self) { genre in
                    Button {
                        toggleGenre(genre)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: genre.icon)
                                .foregroundColor(.yellow)
                                .frame(width: 24)

                            Text(genre.displayName)
                                .font(Font.custom("Poppins", size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedGenres.contains(genre) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.yellow)
                            }
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

    private func toggleGenre(_ genre: MoviesGenre) {
        if selectedGenres.contains(genre) {
            selectedGenres.removeAll { $0 == genre }
        } else {
            selectedGenres.append(genre)
        }
    }
}

#Preview {
    GenrePickerView(selectedGenres: .constant([.crime, .action]))
}
