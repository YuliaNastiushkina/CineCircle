import SwiftUI

struct MovieNoteView: View {
    // MARK: Private interface

    @State private var saveError: String?
    @State private var noteText: String = ""
    @State private var isSaveErrorPresented: Bool = false

    // MARK: Internal interface

    let movieId: Int
    let userId: String
    let movieTitle: String

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            Text("My Note")
                .font(Parameters.titleFont)
                .bold()

            TextEditor(text: $noteText)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Parameters.editorCornerRadius)
                .frame(minHeight: Parameters.editorMinHeight)
                .padding(.horizontal, Parameters.editorHorizontalInset)

            Button("Save Note") {
                let error = NoteService.shared.createOrUpdateNote(
                    for: movieId,
                    userId: userId,
                    content: noteText,
                    movieTitle: movieTitle
                )

                if let error {
                    saveError = error.localizedDescription
                    isSaveErrorPresented = true
                } else {
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear {
            let existing = NoteService.shared.fetchNotes(for: movieId, userId: userId).first
            noteText = existing?.content ?? ""
        }
        .alert("Failed to Save Note", isPresented: $isSaveErrorPresented) {
            Button("OK", role: .cancel) {
                isSaveErrorPresented = false
            }
        } message: {
            Text(saveError ?? "Unknown error")
        }
    }

    private enum Parameters {
        static let contentSpacing: CGFloat = 16
        static let titleFont = Font.title
        static let editorCornerRadius: CGFloat = 10
        static let editorMinHeight: CGFloat = 200
        static let editorHorizontalInset: CGFloat = -4
    }
}

#Preview {
    MovieNoteView(movieId: 1, userId: "previewUser", movieTitle: "Preview Movie")
}
