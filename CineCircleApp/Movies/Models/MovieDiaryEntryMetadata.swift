import Foundation

struct MovieDiaryEntryDraft {
    let privateReflection: String
    let movieTitle: String
    let watchedDate: Date
    let watchType: MovieDiaryWatchType
    let moods: [MovieDiaryMood]
    let watchedWith: MovieDiaryWatchedWith
    let hasSpoilers: Bool
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
