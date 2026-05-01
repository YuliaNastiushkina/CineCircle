import SwiftUI

struct MovieTrailerView: View {
    let trailer: MovieVideo
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                trailerBackground

                Color.black.opacity(Parameters.overlayOpacity)

                Image(systemName: "play.fill")
                    .font(.system(size: Parameters.playIconSize, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: Parameters.playButtonSize, height: Parameters.playButtonSize)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(Parameters.playButtonBorderOpacity), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(Parameters.playButtonShadowOpacity),
                            radius: Parameters.playButtonShadowRadius,
                            x: 0,
                            y: Parameters.playButtonShadowYOffset)

                VStack {
                    Spacer()

                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Parameters.bottomGradientHeight)
                }
            }
            .frame(height: Parameters.height)
            .clipShape(RoundedRectangle(cornerRadius: Parameters.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var trailerBackground: some View {
        if let thumbnailURL = trailer.youtubeThumbnailURL {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .empty:
                    placeholder
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [AppUI.ColorPalette.accent.opacity(0.65), Color.black.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private enum Parameters {
        static let height: CGFloat = 190
        static let cornerRadius: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let playButtonSize: CGFloat = 72
        static let playIconSize: CGFloat = 24
        static let playButtonBorderOpacity: CGFloat = 0.35
        static let playButtonShadowOpacity: CGFloat = 0.35
        static let playButtonShadowRadius: CGFloat = 18
        static let playButtonShadowYOffset: CGFloat = 8
        static let overlayOpacity: CGFloat = 0.18
        static let bottomGradientHeight: CGFloat = 96
        static let titleFontSize: CGFloat = 16
    }
}

#Preview {
    MovieTrailerView(
        trailer: MovieVideo(
            id: "1",
            key: "abc123",
            name: "Official Trailer",
            site: "YouTube",
            type: "Trailer",
            official: true
        ),
        onTap: {}
    )
}
