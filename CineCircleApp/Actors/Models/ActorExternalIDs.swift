/// External social/profile identifiers for a person from TMDB.
struct ActorExternalIDs: Decodable {
    let imdbID: String?
    let instagramID: String?
    let facebookID: String?
    let twitterID: String?
    let tiktokID: String?

    enum CodingKeys: String, CodingKey {
        case imdbID = "imdb_id"
        case instagramID = "instagram_id"
        case facebookID = "facebook_id"
        case twitterID = "twitter_id"
        case tiktokID = "tiktok_id"
    }
}
