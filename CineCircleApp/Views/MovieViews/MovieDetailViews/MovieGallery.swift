import SwiftUI

struct MovieGallery: View {
    let images: [MovieImage]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(images) { image in
                    if let url = URL(string: "https://image.tmdb.org/t/p/w500\(image.filePath)") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: imageWidth, height: imageHeight)
                            case let .success(img):
                                img
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageWidth, height: imageHeight)
                                    .clipped()
                                    .cornerRadius(imageCornerRadius)
                            case .failure:
                                Color.gray.frame(width: imageWidth, height: imageHeight)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
    }

    private let imageWidth: CGFloat = 258
    private let imageHeight: CGFloat = 167
    private let imageCornerRadius: CGFloat = 12
}

#Preview {
    let sampleImages = [
        MovieImage(filePath: "/6DrHO1jr3qVrViUO6s6kFiAGM7.jpg"),
        MovieImage(filePath: "/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg"),
        MovieImage(filePath: "/iQFcwSGbZXMkeyKrxbPnwnRo5fl.jpg"),
    ]

    MovieGallery(images: sampleImages)
}
