import SwiftUI

struct CrewPersonDetailView: View {
    let personID: Int
    let name: String
    let role: String?
    let profilePath: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Parameters.spacing) {
                HStack {
                    Text(name)
                        .font(Parameters.titleFont)
                        .bold()
                    Spacer()
                    LogoView()
                }

                HStack(alignment: .top, spacing: Parameters.spacing) {
                    posterView

                    VStack(alignment: .leading, spacing: Parameters.infoSpacing) {
                        if let role, !role.isEmpty {
                            Text(role)
                                .font(Parameters.roleFont)
                                .fontWeight(.semibold)
                        }

                        if let birthday = viewModel.birthday, !birthday.isEmpty {
                            Text("Born: \(birthday)")
                                .font(Parameters.infoFont)
                        }

                        if let deathday = viewModel.deathday, !deathday.isEmpty {
                            Text("Died: \(deathday)")
                                .font(Parameters.infoFont)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: Parameters.infoSpacing) {
                    Text("Biography")
                        .font(Parameters.sectionFont)
                        .bold()

                    if viewModel.biography.isEmpty {
                        Text("No biography available.")
                            .font(Parameters.bodyFont)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(viewModel.biography)
                            .font(Parameters.bodyFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.fetchActorDetails(for: personID)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @State private var viewModel = ActorDetailsViewModel()

    @ViewBuilder
    private var posterView: some View {
        if let profilePath,
           let url = URL(string: Parameters.posterBaseURL + profilePath) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: Parameters.imageFrameWidth, height: Parameters.imageFrameHeight)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: Parameters.imageFrameWidth, height: Parameters.imageFrameHeight)
                        .clipped()
                        .cornerRadius(Parameters.imageCornerRadius)
                default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        PosterPlaceholderView(
            cornerRadius: Parameters.imageCornerRadius,
            iconSize: Parameters.placeholderIconSize
        )
        .frame(width: Parameters.imageFrameWidth, height: Parameters.imageFrameHeight)
    }

    private enum Parameters {
        static let titleFont = Font.system(.title3, design: .rounded)
        static let sectionFont = Font.system(.title3, design: .rounded)
        static let roleFont = Font.system(.headline, design: .rounded)
        static let infoFont = Font.system(.subheadline, design: .rounded)
        static let bodyFont = Font.system(.body, design: .rounded)
        static let imageFrameWidth: CGFloat = 120
        static let imageFrameHeight: CGFloat = 180
        static let imageCornerRadius: CGFloat = 12
        static let placeholderIconSize: CGFloat = 24
        static let spacing: CGFloat = 16
        static let infoSpacing: CGFloat = 8
        static let posterBaseURL = "https://image.tmdb.org/t/p/w500"
    }
}

#Preview {
    NavigationStack {
        CrewPersonDetailView(
            personID: 1,
            name: "Sample Person",
            role: "Director",
            profilePath: nil
        )
    }
}
