import CoreData
import SwiftUI

/// A singleton class responsible for managing the Core Data stack and operations.
final class CoreDataManager: ObservableObject {
    /// The shared singleton instance of `CoreDataManager`.
    static let shared = CoreDataManager()

    /// The persistent container that encapsulates the Core Data stack.
    let container: NSPersistentContainer

    /// The main context used for performing operations on the main thread.
    var context: NSManagedObjectContext {
        container.viewContext
    }

    /// Published property to show error alerts in views
    @Published var errorMessage: String?

    /// Saves any changes in the main context to the persistent store.
    func save() {
        guard container.viewContext.hasChanges else { return }

        do {
            try container.viewContext.save()
        } catch {
            print("CoreData Save Error:")
            print("- Description: \(error.localizedDescription)")
            print("- Error: \(error)")

            errorMessage = error.localizedDescription
        }
    }

    /// Deletes a specified managed object from the context and saves the changes.
    /// - Parameter item: The `NSManagedObject` to be deleted.
    func delete(item: NSManagedObject) {
        container.viewContext.delete(item)
        save()
    }

    /// Initializes the Core Data stack with the option to use an in-memory store.
    /// Useful for testing purposes or temporary data that doesn’t need to persist between launches.
    /// - Parameter inMemory: A Boolean indicating whether to use an in-memory store. Pass `true` for testing, otherwise `false` (default).
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MovieDataModel")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load in-memory Core Data: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Private interface

    private init() {
        container = NSPersistentContainer(name: "MovieDataModel")
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
    }
}
