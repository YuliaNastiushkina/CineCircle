import Foundation

enum MovieSortOption {
    case title
    case releaseDate

    var sortDescriptor: SortDescriptor<Movie> {
        switch self {
        case .title:
            SortDescriptor(\Movie.title)
        case .releaseDate:
            SortDescriptor(\Movie.releaseDate)
        }
    }
}
