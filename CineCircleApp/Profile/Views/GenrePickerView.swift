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
                        HStack(spacing: Parameters.rowSpacing) {
                            Image(systemName: genre.icon)
                                .foregroundColor(.yellow)
                                .frame(width: Parameters.iconWidth)

                            Text(genre.displayName)
                                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.fontSize))
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
            .navigationTitle(Parameters.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Parameters.doneLabel) {
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

    private enum Parameters {
        static let title = "Select Genres"
        static let doneLabel = "Done"
        static let fontSize: CGFloat = 16
        static let rowSpacing: CGFloat = 12
        static let iconWidth: CGFloat = 24
    }
}

#Preview {
    GenrePickerView(selectedGenres: .constant([.crime, .action]))
}
