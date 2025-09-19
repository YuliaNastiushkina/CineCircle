import SwiftUI

struct PersonItemView: View {
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
                            .frame(width: imageWidth, height: imageWidth)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageWidth, height: imageWidth)
                            .clipShape(Circle())
                            .shadow(color: .gray, radius: shadowRadius)
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
                    .font(Font.custom(poppinsFont, size: textSize))
                    .frame(alignment: .top)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }

            Text(name)
                .foregroundStyle(Color.secondary)
                .font(Font.custom(poppinsFont, size: textSize))
                .frame(width: textFrameWidth, height: textFreimHeight, alignment: .top)
                .lineLimit(nameLineLimit)
                .multilineTextAlignment(.center)
        }
        .frame(width: imageWidth)
    }

    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(circleOpacity))
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: imageWidth * placeholderIconScale, height: imageWidth * placeholderIconScale)
                .foregroundColor(.white)
        }
        .frame(width: imageWidth, height: imageWidth)
    }

    // MARK: - Private interface

    private let textFrameWidth: CGFloat = 80
    private let textFreimHeight: CGFloat = 35
    private let shadowRadius: CGFloat = 0.5
    private let circleOpacity: CGFloat = 0.6
    private let placeholderIconScale: CGFloat = 0.5
    private let poppinsFont = "Poppins"
    private let textSize: CGFloat = 12
    private let imageWidth: CGFloat = 80
}

#Preview {
    PersonItemView(name: "Rich Lee", role: "Director", profilePath: "", nameLineLimit: 1)
}
