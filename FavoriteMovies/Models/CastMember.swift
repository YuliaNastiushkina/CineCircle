import Foundation
import SwiftData

/// Represents the structure of the movie's cast.
@Model
class CastMember {
    /// Name of the actor.
    var actorName: String
    /// Movies in which the actor is participating.
    var movies = [Movie]()
    
    /// Initializes the actor with its name.
    /// - Parameter actorName: Name of the actor.
    init(actorName: String) {
        self.actorName = actorName
    }
    
    /// Sample actors for preview or testing.
    static let sampleData = [
        CastMember(actorName: "Johnny Depp"),
        CastMember(actorName: "Keira Knightley"),
        CastMember(actorName: "Al Pacino"),
        CastMember(actorName: "Salvatore Corsitto"),
        CastMember(actorName: "Zoe Saldaña"),
    ]
}
