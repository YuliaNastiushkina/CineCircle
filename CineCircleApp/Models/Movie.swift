import Foundation
import SwiftData

/// A movie with its details and relations to cast and friends.
@Model
class Movie {
    /// Movie title.
    var title: String
    /// Movie release date.
    var releaseDate: Date
    /// Friends who marked this movie as their favorite.
    var favoritedBy = [Friend]()
    /// The cast of the movie.
    @Relationship(inverse: \CastMember.movies) var cast = [CastMember]()
    /// String representation of movie release date. Used for sorting.
    var releaseDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: releaseDate)
    }

    /// Initializes a new movie with a title and release date.
    /// - Parameters:
    ///   - title: The title of the movie.
    ///   - releaseDate: The release date of the movie.
    init(title: String, releaseDate: Date) {
        self.title = title
        self.releaseDate = releaseDate
    }

    /// Sample movies for preview or testing.
    static let sampleData: [Movie] = [
        .init(title: "The Shawshank Redemption", releaseDate: Date(timeIntervalSince1970: 0)),
        .init(title: "The Godfather", releaseDate: Date(timeIntervalSince1970: 1)),
        .init(title: "The Godfather: Part II", releaseDate: Date(timeIntervalSince1970: 2)),
        .init(title: "Amusing Space Traveler 3", releaseDate: Date(timeIntervalSinceReferenceDate: -402_000_000)),
        .init(title: "The Last Venture", releaseDate: Date(timeIntervalSinceReferenceDate: 550_000_000)),
        .init(title: "Pirates of the Caribbean", releaseDate: Date(timeIntervalSinceReferenceDate: 550_000_000)),
    ]
}
