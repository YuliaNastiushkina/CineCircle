import SwiftUI

struct ProfileHeaderView: View {
    let viewModel: ProfileViewModel
    let isEditing: Bool
    let profileImage: UIImage?
    let stats: MovieStats
    let onProfileImageTap: () -> Void

    var body: some View {
        VStack(spacing: Parameters.containerSpacing) {
            // Profile Avatar
            Button(action: {
                if isEditing { onProfileImageTap() }
            }) {
                ZStack(alignment: .bottomTrailing) {
                    avatarView

                    if isEditing {
                        Image(systemName: "camera.fill")
                            .font(.system(size: Parameters.cameraIconSize, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(Parameters.cameraBadgePadding)
                            .background(Circle().fill(AppUI.ColorPalette.accent))
                            .offset(x: Parameters.cameraBadgeOffset, y: Parameters.cameraBadgeOffset)
                    }
                }
            }
            .buttonStyle(.plain)

            // Name & Subtitle
            VStack(spacing: Parameters.textSpacing) {
                Text(viewModel.name.isEmpty ? "CineCircle User" : viewModel.name)
                    .font(Font.custom(AppUI.FontName.poppinsBold, size: Parameters.nameFontSize))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, Parameters.verticalPadding)
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarView: some View {
        if let profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Parameters.avatarSize, height: Parameters.avatarSize)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppUI.ColorPalette.accent.opacity(0.5), lineWidth: Parameters.avatarBorderWidth)
                )
        } else {
            Circle()
                .fill(AppUI.ColorPalette.softCardBackground)
                .frame(width: Parameters.avatarSize, height: Parameters.avatarSize)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: Parameters.placeholderIconSize))
                        .foregroundColor(AppUI.ColorPalette.accent)
                )
        }
    }

    // MARK: - Subtitle

    private var subtitle: String {
        let watched = stats.totalWatched
        if watched == 0 {
            return "Welcome to CineCircle!"
        } else {
            let movieWord = watched == 1 ? "movie" : "movies"
            return "\(watched) \(movieWord) watched"
        }
    }

    // MARK: - Design Constants

    private enum Parameters {
        static let containerSpacing: CGFloat = 16
        static let textSpacing: CGFloat = 4
        static let verticalPadding: CGFloat = 20
        static let avatarSize: CGFloat = 100
        static let avatarBorderWidth: CGFloat = 4
        static let placeholderIconSize: CGFloat = 36
        static let cameraIconSize: CGFloat = 13
        static let cameraBadgePadding: CGFloat = 7
        static let cameraBadgeOffset: CGFloat = -2
        static let nameFontSize: CGFloat = 24
        static let subtitleFontSize: CGFloat = 14
    }
}

#Preview {
    ProfileHeaderView(
        viewModel: ProfileViewModel(userId: "previewUser", authService: FirebaseAuthService()),
        isEditing: false,
        profileImage: nil,
        stats: MovieStats(totalWatched: 12, totalSaved: 5, totalNotes: 3),
        onProfileImageTap: {}
    )
}
