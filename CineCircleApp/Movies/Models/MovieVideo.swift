import Foundation

/// Represents a single video entry returned by TMDB for a movie.
struct MovieVideo: Decodable, Identifiable {
    /// The unique TMDB identifier for the video.
    let id: String
    /// The provider-specific video key, used to build playback URLs.
    let key: String
    /// The display title of the video.
    let name: String
    /// The hosting platform for the video, such as `YouTube`.
    let site: String
    /// The kind of video, such as `Trailer` or `Teaser`.
    let type: String
    /// Indicates whether the video is marked official by TMDB.
    let official: Bool

    /// A thumbnail image URL for YouTube-hosted videos.
    var youtubeThumbnailURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(key)/hqdefault.jpg")
    }

    /// A standard watch URL for YouTube-hosted videos.
    var youtubeWatchURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
}
