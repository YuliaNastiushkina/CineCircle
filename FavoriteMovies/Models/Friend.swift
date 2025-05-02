import Foundation
import SwiftData

/// Describes a friend and their favorite movies.
@Model
class Friend {
    /// Name of person.
    var name: String
    /// The person's favorite movie. If there is no favorite movie, the value is `nil`.
    var favoriteMovie: Movie?
    
    /// Initializes the friend with its name.
    /// - Parameter name: Name of person.
    init(name: String) {
        self.name = name
    }
    
    /// Sample friends for preview or testing.
    static let sampleData = [
        Friend(name: "Elena"),
        Friend(name: "Graham"),
        Friend(name: "Mayuri"),
        Friend(name: "Rich"),
        Friend(name: "Rody"),
    ]
}
