/// Represents a single image associated with a movie, typically used for backdrops or gallery.
struct MovieImage: Decodable, Identifiable {
    let filePath: String
    var id: String { filePath }

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
    }
}
