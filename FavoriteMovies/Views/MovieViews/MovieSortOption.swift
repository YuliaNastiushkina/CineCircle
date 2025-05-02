import Foundation

enum MovieSortOption {
    case title
    case releaseDate
    
    var sortDescriptor: SortDescriptor<Movie> {
        switch self {
        case .title:
            return SortDescriptor(\Movie.title)
        case .releaseDate:
            return SortDescriptor(\Movie.releaseDate)
        }
    }
}
