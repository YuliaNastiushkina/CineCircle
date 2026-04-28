/// Detailed information about an actor from TMDB.
struct ActorDetails: Codable {
    /// Actor ID.
    let id: Int
    /// Actor name.
    let name: String
    /// Full biography text.
    let biography: String
    /// Actor's date of birth.
    let birthday: String?
    /// Actor's date of death.
    let deathday: String?
}
