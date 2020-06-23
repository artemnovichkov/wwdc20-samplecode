/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class that loads and configures the application's persistence layer.
*/

import CoreData
import os

final class CoreDataStore: ObservableObject {
    private lazy var container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "MemoryGame")

        container.loadPersistentStores { store, error in
            if let error = error {
                fatalError("Failed to load persistent store. {error=\(error as NSError)}")
            }
        }

        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
}
