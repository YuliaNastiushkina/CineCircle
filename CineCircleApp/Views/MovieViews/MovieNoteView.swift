import SwiftUI

struct MovieNoteView: View {
    // MARK: Private interface

    @State private var saveError: String?
    @State private var noteText: String = ""
    @State private var isSaveErrorPresented: Bool = false

    // MARK: Internal interface

    let movieId: Int
    let userId: String

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Note")
                .font(.title)
                .bold()

            TextEditor(text: $noteText)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .frame(minHeight: 200)
                .padding(.horizontal, -4)

            Button("Save Note") {
                let error = NoteService.shared.createOrUpdateNote(
                    for: movieId,
                    userId: userId,
                    content: noteText
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
}

#Preview {
    MovieNoteView(movieId: 1, userId: "previewUser")
}
