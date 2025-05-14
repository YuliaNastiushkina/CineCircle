import SwiftData
import SwiftUI

struct MovieDetail: View {
    let movie: RemoteMovie

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let posterPath = movie.posterPath {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 300)
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                                .frame(height: 300)
                        default:
                            EmptyView()
                        }
                    }
                }

                Text(movie.title)
                    .font(.system(.title, design: .rounded))
                    .bold()

                Text("⭐️ \(String(format: "%.1f", movie.voteAverage))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text("Release date: \(movie.releaseDate)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Divider()

                Text(movie.overview)
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .navigationTitle(movie.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    let sampleMovie = RemoteMovie(
        id: 1,
        title: "Sonic 2. The Hedgehog",
        overview: "When Dr. Robotnik returns with a new partner, Knuckles, in search of an emerald that has the power to destroy civilizations, Sonic teams up with his own sidekick, Tails, on a journey across the world to find the emerald first.",
        posterPath: "/6DrHO1jr3qVrViUO6s6kFiAGM7.jpg",
        voteAverage: 7.5,
        releaseDate: "2024-10-12"
    )

    NavigationStack {
        MovieDetail(movie: sampleMovie)
    }
}
