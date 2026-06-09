import Foundation

enum TVGenre: Int, CaseIterable, Identifiable {
    case actionAdventure = 10759
    case animation = 16
    case comedy = 35
    case crime = 80
    case documentary = 99
    case drama = 18
    case family = 10751
    case kids = 10762
    case mystery = 9648
    case news = 10763
    case reality = 10764
    case sciFiFantasy = 10765
    case soap = 10766
    case talk = 10767
    case warPolitics = 10768
    case western = 37

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .actionAdventure: "Action & Adventure"
        case .animation: "Animation"
        case .comedy: "Comedy"
        case .crime: "Crime"
        case .documentary: "Documentary"
        case .drama: "Drama"
        case .family: "Family"
        case .kids: "Kids"
        case .mystery: "Mystery"
        case .news: "News"
        case .reality: "Reality"
        case .sciFiFantasy: "Sci-Fi & Fantasy"
        case .soap: "Soap"
        case .talk: "Talk"
        case .warPolitics: "War & Politics"
        case .western: "Western"
        }
    }

    static func name(for id: Int) -> String? {
        TVGenre(rawValue: id)?.displayName
    }

    func matches(movieGenre: MoviesGenre) -> Bool {
        switch self {
        case .actionAdventure:
            movieGenre == .action || movieGenre == .adventure
        case .sciFiFantasy:
            movieGenre == .scienceFiction || movieGenre == .fantasy
        case .warPolitics:
            movieGenre == .war || movieGenre == .history
        case .animation:
            movieGenre == .animation
        case .comedy:
            movieGenre == .comedy
        case .crime:
            movieGenre == .crime
        case .documentary:
            movieGenre == .documentary
        case .drama:
            movieGenre == .drama
        case .family, .kids:
            movieGenre == .family
        case .mystery:
            movieGenre == .mystery
        case .western:
            movieGenre == .western
        case .news, .reality, .soap, .talk:
            false
        }
    }
}
