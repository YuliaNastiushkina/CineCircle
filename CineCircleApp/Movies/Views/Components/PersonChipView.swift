import SwiftUI

struct PersonChipView: View {
    let name: String
    let role: String?
    let profilePath: String?
    let nameLineLimit: Int

    var body: some View {
        VStack {
            if let profilePath,
               !profilePath.isEmpty,
               let url = URL(string: "https://image.tmdb.org/t/p/w500\(profilePath)") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: Parameters.imageWidth, height: Parameters.imageWidth)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: Parameters.imageWidth, height: Parameters.imageWidth)
                            .clipped()
                            .clipShape(Circle())
                            .shadow(color: .gray, radius: Parameters.shadowRadius)
                    case .failure:
                        placeholderView
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                placeholderView
            }

            if let role {
                Text(role)
                    .foregroundStyle(Color.black)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.textFontSize))
                    .frame(alignment: .top)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }

            Text(name)
                .foregroundStyle(Color.secondary)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.textFontSize))
                .frame(width: Parameters.textFrameWidth, height: Parameters.textFrameHeight, alignment: .top)
                .lineLimit(nameLineLimit)
                .multilineTextAlignment(.center)
        }
        .frame(width: Parameters.imageWidth)
    }

    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(Parameters.placeholderOpacity))
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(
                    width: Parameters.imageWidth * Parameters.placeholderIconScale,
                    height: Parameters.imageWidth * Parameters.placeholderIconScale
                )
                .foregroundColor(.white)
        }
        .frame(width: Parameters.imageWidth, height: Parameters.imageWidth)
    }

    // MARK: - Private interface

    private enum Parameters {
        static let textFrameWidth: CGFloat = 80
        static let textFrameHeight: CGFloat = 35
        static let shadowRadius: CGFloat = 0.5
        static let placeholderOpacity: CGFloat = 0.6
        static let placeholderIconScale: CGFloat = 0.5
        static let textFontSize: CGFloat = 12
        static let imageWidth: CGFloat = 80
    }
}

#Preview {
    PersonChipView(name: "Rich Lee", role: "Director", profilePath: "", nameLineLimit: 1)
}
