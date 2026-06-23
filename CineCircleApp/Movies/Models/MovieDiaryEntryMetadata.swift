import Foundation

struct MovieDiaryEntryDraft {
    let privateReflection: String
    let title: String
    let parentTitle: String?
    let watchedDate: Date
    let watchType: MovieDiaryWatchType
    let moods: [MovieDiaryMood]
    let watchedWith: MovieDiaryWatchedWith
    let hasSpoilers: Bool

    init(
        privateReflection: String,
        title: String,
        parentTitle: String? = nil,
        watchedDate: Date,
        watchType: MovieDiaryWatchType,
        moods: [MovieDiaryMood],
        watchedWith: MovieDiaryWatchedWith,
        hasSpoilers: Bool
    ) {
        self.privateReflection = privateReflection
        self.title = title
        self.parentTitle = parentTitle
        self.watchedDate = watchedDate
        self.watchType = watchType
        self.moods = moods
        self.watchedWith = watchedWith
        self.hasSpoilers = hasSpoilers
    }

    init(
        privateReflection: String,
        movieTitle: String,
        watchedDate: Date,
        watchType: MovieDiaryWatchType,
        moods: [MovieDiaryMood],
        watchedWith: MovieDiaryWatchedWith,
        hasSpoilers: Bool
    ) {
        self.init(
            privateReflection: privateReflection,
            title: movieTitle,
            watchedDate: watchedDate,
            watchType: watchType,
            moods: moods,
            watchedWith: watchedWith,
            hasSpoilers: hasSpoilers
        )
    }
}

enum MovieDiaryEntryTarget: Equatable {
    case movie(movieId: Int)
    case tvEpisode(showId: Int, episodeId: Int, seasonNumber: Int, episodeNumber: Int)

    var mediaType: MovieDiaryMediaType {
        switch self {
        case .movie: .movie
        case .tvEpisode: .tvEpisode
        }
    }
}

enum MovieDiaryMediaType: String {
    case movie
    case tvEpisode
}

extension MovieDiary {
    var diaryMediaType: MovieDiaryMediaType {
        MovieDiaryMediaType(rawValue: mediaType ?? "") ?? .movie
    }

    var diaryDisplayTitle: String {
        switch diaryMediaType {
        case .movie:
            movieTitle ?? "Movie #\(movieID)"
        case .tvEpisode:
            if let showTitle = diaryShowTitle {
                "\(showTitle) · \(diaryEpisodeCode)"
            } else {
                diaryEpisodeCode
            }
        }
    }

    var diarySubtitle: String? {
        switch diaryMediaType {
        case .movie:
            nil
        case .tvEpisode:
            movieTitle
        }
    }

    private var diaryEpisodeCode: String {
        "S\(seasonNumber) E\(episodeNumber)"
    }

    private var diaryShowTitle: String? {
        guard let parentTitle, !parentTitle.isEmpty else { return nil }

        let separator = " · "
        if parentTitle.contains(separator) {
            let parts = parentTitle.components(separatedBy: separator)
            if let first = parts.first, first.hasPrefix("S"), let last = parts.last {
                return last
            }
        }

        return parentTitle
    }
}

enum MovieDiaryMood: String, CaseIterable, Identifiable {
    case moved
    case exhilarated
    case amused
    case thoughtful
    case awed
    case haunted
    case unsettled
    case comforted
    case nostalgic
    case leftMeCold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .moved: "Moved"
        case .exhilarated: "Exhilarated"
        case .amused: "Amused"
        case .thoughtful: "Thoughtful"
        case .awed: "Awed"
        case .haunted: "Haunted"
        case .unsettled: "Unsettled"
        case .comforted: "Comforted"
        case .nostalgic: "Nostalgic"
        case .leftMeCold: "Left me cold"
        }
    }

    static func encoded(_ moods: [MovieDiaryMood]) -> String? {
        guard !moods.isEmpty else { return nil }
        return moods.map(\.rawValue).joined(separator: ",")
    }

    static func decoded(from rawValue: String?) -> [MovieDiaryMood] {
        guard let rawValue, !rawValue.isEmpty else { return [] }
        return rawValue
            .split(separator: ",")
            .compactMap { MovieDiaryMood(rawValue: String($0)) }
    }
}

enum MovieDiaryWatchType: String, CaseIterable, Identifiable {
    case firstWatch
    case rewatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstWatch: "First watch"
        case .rewatch: "Rewatch"
        }
    }
}

enum MovieDiaryWatchedWith: String, CaseIterable, Identifiable {
    case alone
    case partner
    case friends
    case family
    case date
    case kids

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alone: "Alone"
        case .partner: "Partner"
        case .friends: "Friends"
        case .family: "Family"
        case .date: "Date"
        case .kids: "Kids"
        }
    }
}
