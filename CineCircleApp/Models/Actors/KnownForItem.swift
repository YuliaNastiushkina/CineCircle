/// Represents a movie or TV show the actor is known for.
struct KnownForItem: Codable, Identifiable {
    /// Unique ID for the item.
    let id: Int
    /// Title of the movie or name of the show (may be `nil`).
    let title: String?
}
