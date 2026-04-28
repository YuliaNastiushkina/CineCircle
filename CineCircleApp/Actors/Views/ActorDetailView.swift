import SwiftData
import SwiftUI

struct ActorDetailView: View {
    let actor: RemoteActor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Parameters.spacing) {
                HStack {
                    Text(actor.name)
                        .font(Parameters.titleFont)
                        .bold()
                    Spacer()
                    LogoView()
                }

                HStack(alignment: .top, spacing: Parameters.spacing) {
                    if let path = actor.profilePath,
                       let url = URL(string: Parameters.posterBaseURL + path) {
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
                                PosterPlaceholderView(
                                    cornerRadius: Parameters.imageCornerRadius,
                                    iconSize: Parameters.placeholderIconSize
                                )
                                .frame(width: Parameters.imageFrameWidth, height: Parameters.imageFrameHeight)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Parameters.infoSpacing) {
                        if let birthday = viewModel.birthday {
                            Text("🎂 Born: \(birthday)")
                                .font(Parameters.infoFont)
                        }

                        if let deathday = viewModel.deathday, !deathday.isEmpty {
                            Text("🪦 Died: \(deathday)")
                                .font(Parameters.infoFont)
                        }

                        Text("🎬 Known for:")
                            .font(Parameters.infoFont)
                            .fontWeight(.semibold)

                        Text(
                            actor.knownFor
                                .map { $0.title ?? $0.name ?? "Unknown" }
                                .joined(separator: ", ")
                        )
                        .font(Parameters.infoFont)
                        .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Biography")
                        .font(Parameters.titleFont)
                        .bold()

                    if !viewModel.biography.isEmpty {
                        Text(viewModel.biography)
                            .font(Parameters.bodyFont)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No biography available.")
                            .font(Parameters.bodyFont)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.fetchActorDetails(for: actor.id)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: Private interface

    @State private var viewModel = ActorDetailsViewModel()

    private enum Parameters {
        static let titleFont = Font.system(.title3, design: .rounded)
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
    let sampleActor: RemoteActor = .init(
        id: 1,
        name: "John Doe",
        knownFor: [KnownForItem(id: 1, title: "Some title", name: "Some name")],
        profilePath: "/path/to/profile.jpg"
    )
    ActorDetailView(actor: sampleActor)
}
