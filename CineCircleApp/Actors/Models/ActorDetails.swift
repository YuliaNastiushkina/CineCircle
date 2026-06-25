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
    /// Actor's birth location.
    let placeOfBirth: String?
    /// Alternate names credited to the actor.
    let alsoKnownAs: [String]
    /// Actor's official website.
    let homepage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case biography
        case birthday
        case deathday
        case placeOfBirth = "place_of_birth"
        case alsoKnownAs = "also_known_as"
        case homepage
    }
}
