import SwiftUI

struct ProfileView: View {
    // MARK: Private interface

    @State private var showGenrePicker = false
    @State private var isEditing = false
    @State private var showNameAlert = false

    @StateObject private var viewModel = ProfileViewModel()

    // MARK: Internal interface

    @EnvironmentObject var authService: AuthService
    var body: some View {
        NavigationView {
            HStack {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Name:")

                        if isEditing {
                            TextField("Your name", text: $viewModel.name)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text(viewModel.name.isEmpty ? "Add your name" : viewModel.name)
                                .foregroundColor(viewModel.name.isEmpty ? .gray : .primary)
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

                        if !viewModel.favoriteGenres.isEmpty {
                            Text(viewModel.favoriteGenres.map(\.rawValue.capitalized).joined(separator: ", "))
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
                            if isEditing {
                                if viewModel.saveProfile() {
                                    isEditing = false
                                } else {
                                    showNameAlert = true
                                }
                            } else {
                                isEditing = true
                            }
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
                    GenrePickerView(selectedGenres: $viewModel.favoriteGenres)
                }
                .alert("Name is required", isPresented: $showNameAlert) {
                    Button("OK", role: .cancel) {}
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
