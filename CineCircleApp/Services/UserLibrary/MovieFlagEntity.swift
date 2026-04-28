import CoreData

/// Protocol for Core Data entities that store user flags for movies.
/// Used for `WatchedMovie` and `SavedMovie`.
protocol MovieFlagEntity where Self: NSManagedObject {
    var id: UUID? { get set }
    var movieID: Int32 { get set }
    var userID: String? { get set }
}

extension WatchedMovie: MovieFlagEntity {}
extension SavedMovie: MovieFlagEntity {}
