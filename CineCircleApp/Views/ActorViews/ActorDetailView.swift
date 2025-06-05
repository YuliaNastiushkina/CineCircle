import SwiftData
import SwiftUI

struct ActorDetailView: View {
    let actor: RemoteActor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                HStack {
                    Text(actor.name)
                        .font(titleFont)
                        .bold()
                    Spacer()
                    LogoView()
                }

                HStack(alignment: .top, spacing: spacing) {
                    if let path = actor.profilePath,
                       let url = URL(string: posterBaseURL + path) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: imageFrameWidth, height: imageFrameHeight)
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageFrameWidth, height: imageFrameHeight)
                                    .clipped()
                                    .cornerRadius(imageCornerRadius)
                            default:
                                Color.gray
                                    .frame(width: imageFrameWidth, height: imageFrameHeight)
                                    .cornerRadius(imageCornerRadius)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        if let birthday = viewModel.birthday {
                            Text("🎂 Born: \(birthday)")
                                .font(infoFont)
                        }

                        if let deathday = viewModel.deathday, !deathday.isEmpty {
                            Text("🪦 Died: \(deathday)")
                                .font(infoFont)
                        }

                        Text("🎬 Known for:")
                            .font(infoFont)
                            .fontWeight(.semibold)

                        Text(
                            actor.knownFor
                                .map { $0.title ?? "Unknown" }
                                .joined(separator: ", ")
                        )
                        .font(infoFont)
                        .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Biography")
                        .font(titleFont)
                        .bold()

                    if !viewModel.biography.isEmpty {
                        Text(viewModel.biography)
                            .font(bodyFont)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No biography available.")
                            .font(bodyFont)
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

    private let titleFont = Font.system(.title3, design: .rounded)
    private let infoFont = Font.system(.subheadline, design: .rounded)
    private let bodyFont = Font.system(.body, design: .rounded)

    private let imageFrameWidth: CGFloat = 120
    private let imageFrameHeight: CGFloat = 180
    private let imageCornerRadius: CGFloat = 12
    private let spacing: CGFloat = 16

    private let posterBaseURL = "https://image.tmdb.org/t/p/w500"
}

#Preview {
    let sampleActor: RemoteActor = .init(
        id: 1,
        name: "John Doe",
        knownFor: [KnownForItem(id: 1, title: "Some title")],
        profilePath: "/path/to/profile.jpg"
    )
    ActorDetailView(actor: sampleActor)
}
