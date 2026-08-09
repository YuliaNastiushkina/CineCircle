import Foundation

struct ProfileNoteItem: Identifiable {
    let id: String
    let mediaType: MovieDiaryMediaType
    let movieID: Int
    let title: String
    let subtitle: String?
    let content: String
    let createdAt: Date?
    let watchedDate: Date?
    let moods: [MovieDiaryMood]
    let watchType: MovieDiaryWatchType
    let watchedWith: MovieDiaryWatchedWith
    let hasSpoilers: Bool
}
