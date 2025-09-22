import SwiftUI

struct NoteButton: View {
    let movieId: Int
    let userId: String

    var body: some View {
        Button {
            isPresentingNote = true
        } label: {
            HStack {
                Text("Write a note")
                Image("notebookImage")
                    .renderingMode(.template)
            }
            .font(Font.custom("Poppins", size: 16))
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(width: 370, alignment: .center)
            .background(Color.yellow)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
        .sheet(isPresented: $isPresentingNote) {
            MovieNoteView(movieId: movieId, userId: userId)
        }
    }

    // MARK: - Private interface

    @State private var isPresentingNote = false
}

#Preview {
    NoteButton(movieId: 1, userId: "previewUser")
}
