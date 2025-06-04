import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService

    @State private var name: String = ""
    @State private var favoriteGenre: [MoviesGenre] = []
    @State private var showGenrePicker = false
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            HStack {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Name:")

                        if isEditing {
                            TextField("Your name", text: $name)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text(name.isEmpty ? "Add your name" : name)
                                .foregroundColor(name.isEmpty ? .gray : .primary)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical)

                    VStack(alignment: .leading) {
                        Text("Favorite genres:")

                        if isEditing {
                            Button(action: {
                                showGenrePicker = true
                            }, label: {
                                HStack {
                                    Text("Select genres")
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                            })
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }

                        if !favoriteGenre.isEmpty {
                            Text(favoriteGenre.map(\.rawValue.capitalized).joined(separator: ", "))
                                .foregroundColor(.secondary)
                        } else {
                            Text("No genres selected")
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditing ? "Done" : "Edit") {
                            isEditing.toggle()
                        }
                    }

                    if !isEditing {
                        ToolbarItem(placement: .bottomBar) {
                            Button("Sign out") {
                                authService.signOut()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red.opacity(0.8))
                        }
                    }
                }
                .sheet(isPresented: $showGenrePicker) {
                    GenrePickerView(selectedGenres: $favoriteGenre)
                }
                .navigationTitle("Your Profile")

                Spacer()
            }
        }
    }
}

#Preview {
    ProfileView()
}
