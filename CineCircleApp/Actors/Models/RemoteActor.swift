/// An actor that we fetch from the `api.themoviedb.org`.
struct RemoteActor: Codable, Identifiable {
    /// Actor ID.
    let id: Int
    /// Actor name.
    let name: String
    /// A list of movies the actor is known for.
    let knownFor: [KnownForItem]
    /// The relative path to the actor's profile image.
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case knownFor = "known_for"
        case profilePath = "profile_path"
    }
}
