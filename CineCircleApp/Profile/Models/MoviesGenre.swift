import Foundation

enum MoviesGenre: String, CaseIterable, Identifiable {
    case action
    case adventure
    case animation
    case comedy
    case crime
    case documentary
    case drama
    case family
    case fantasy
    case history
    case horror
    case music
    case mystery
    case romance
    case scienceFiction = "science-fiction"
    case tvMovie = "tv-movie"
    case thriller
    case war
    case western

    var id: Int {
        switch self {
        case .action: 28
        case .adventure: 12
        case .animation: 16
        case .comedy: 35
        case .crime: 80
        case .documentary: 99
        case .drama: 18
        case .family: 10751
        case .fantasy: 14
        case .history: 36
        case .horror: 27
        case .music: 10402
        case .mystery: 9648
        case .romance: 10749
        case .scienceFiction: 878
        case .tvMovie: 10770
        case .thriller: 53
        case .war: 10752
        case .western: 37
        }
    }

    var displayName: String {
        switch self {
        case .scienceFiction: "Science Fiction"
        case .tvMovie: "TV Movie"
        default: rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .action: "flame.fill"
        case .adventure: "map.fill"
        case .animation: "wand.and.stars"
        case .comedy: "face.smiling.fill"
        case .crime: "shield.fill"
        case .documentary: "camera.fill"
        case .drama: "theatermasks.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .fantasy: "sparkles"
        case .history: "building.columns.fill"
        case .horror: "eye.trianglebadge.exclamationmark.fill"
        case .music: "music.note"
        case .mystery: "magnifyingglass"
        case .romance: "heart.fill"
        case .scienceFiction: "atom"
        case .tvMovie: "tv.fill"
        case .thriller: "bolt.fill"
        case .war: "flag.fill"
        case .western: "sun.dust.fill"
        }
    }

    static func fromStoredValue(_ value: String) -> MoviesGenre? {
        switch value {
        case "sci-fi": .scienceFiction
        case "historical": .history
        case "detective": .mystery
        default: MoviesGenre(rawValue: value)
        }
    }

    static func genre(forTMDBID id: Int) -> MoviesGenre? {
        allCases.first { $0.id == id }
    }
}
