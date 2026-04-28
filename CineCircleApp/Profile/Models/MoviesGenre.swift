import Foundation

enum MoviesGenre: String, CaseIterable {
    case action
    case comedy
    case drama
    case romance
    case horror
    case fantasy
    case sciFi = "sci-fi"
    case mystery
    case thriller
    case western
    case adventure
    case crime
    case detective
    case historical

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .action: "flame.fill"
        case .comedy: "face.smiling.fill"
        case .drama: "theatermasks.fill"
        case .romance: "heart.fill"
        case .horror: "eye.trianglebadge.exclamationmark.fill"
        case .fantasy: "sparkles"
        case .sciFi: "atom"
        case .mystery: "magnifyingglass"
        case .thriller: "bolt.fill"
        case .western: "sun.dust.fill"
        case .adventure: "map.fill"
        case .crime: "shield.fill"
        case .detective: "eyeglasses"
        case .historical: "building.columns.fill"
        }
    }
}
