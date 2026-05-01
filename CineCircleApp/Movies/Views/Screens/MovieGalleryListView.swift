import SwiftUI

struct MovieGalleryListView: View {
    let title: String
    let images: [MovieImage]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Parameters.spacing) {
                ForEach(images) { image in
                    if let url = URL(string: Parameters.posterBaseURL + image.filePath) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: Parameters.imageHeight)
                            case let .success(loadedImage):
                                loadedImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: Parameters.imageHeight)
                                    .clipped()
                                    .cornerRadius(Parameters.cornerRadius)
                            case .failure:
                                Color.gray
                                    .frame(maxWidth: .infinity)
                                    .frame(height: Parameters.imageHeight)
                                    .cornerRadius(Parameters.cornerRadius)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private enum Parameters {
        static let posterBaseURL = "https://image.tmdb.org/t/p/w500"
        static let imageHeight: CGFloat = 220
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 16
    }
}

#Preview {
    NavigationStack {
        MovieGalleryListView(
            title: "Gallery",
            images: [
                MovieImage(filePath: "/6DrHO1jr3qVrViUO6s6kFiAGM7.jpg"),
                MovieImage(filePath: "/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg"),
            ]
        )
    }
}
