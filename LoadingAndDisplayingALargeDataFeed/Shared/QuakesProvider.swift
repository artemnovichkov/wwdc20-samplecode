/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to fetch data from the remote server and save it to the Core Data store.
*/
import CoreData

class QuakesProvider {
    /**
     Geological data provided by the U.S. Geological Survey (USGS). See ACKNOWLEDGMENTS.txt for additional details.
     */
    let earthquakesFeed = "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson"
    
    // MARK: - Core Data
    
    /**
     A persistent container to set up the Core Data stack.
    */
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Earthquakes")
        
        if #available(iOS 13, macOS 10.15, *) {
            // Enable remote notifications
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { storeDesription, error in
            guard error == nil else {
                fatalError("Unresolved error \(error!)")
            }
        }

        // This sample refreshes UI by refetching data, so doesn't need to merge the changes.
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        if #available(iOS 13, macOS 10.15, *) {
            // Observe Core Data remote change notifications.
            NotificationCenter.default.addObserver(
                self, selector: #selector(type(of: self).storeRemoteChange(_:)),
                name: .NSPersistentStoreRemoteChange, object: nil)
        }
        return container
    }()
    
    /**
     Creates and configures a private queue context.
    */
    private func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    /**
     Fetches the earthquake feed from the remote server, and imports it into Core Data.
     
     Because this server does not offer a secure communication channel, this example
     uses an http URL and adds "earthquake.usgs.gov" to the "NSExceptionDomains" value
     in the apps's info.plist. When you commmunicate with your own servers, or when
     the services you use offer a secure communication option, you should always
     prefer to use https.
    */
    func fetchQuakes(completionHandler: @escaping (Error?) -> Void) {
        // Create a URL to load, and a URLSession to load it.
        guard let jsonURL = URL(string: earthquakesFeed) else {
            completionHandler(QuakeError.urlError)
            return
        }
        let session = URLSession(configuration: .default)
        
        // Create a URLSession dataTask to fetch the feed.
        let task = session.dataTask(with: jsonURL) { data, _, urlSessionError in
            
            // Alert any error returned by URLSession.
            guard urlSessionError == nil else {
                completionHandler(urlSessionError)
                return
            }
            
            // Alert the user if no data comes back.
            guard let data = data else {
                completionHandler(QuakeError.networkUnavailable)
                return
            }
            
            // Decode the JSON and import it into Core Data.
            do {
                // Decode the JSON into codable type GeoJSON.
                let geoJSON = try JSONDecoder().decode(GeoJSON.self, from: data)
                print("\(Date()) Got \(geoJSON.quakePropertiesList.count) records.")

                print("\(Date()) Start importing data to the store ...")
                // Import the GeoJSON into Core Data.
                if #available(iOS 13, macOS 10.15, *) {
                    try self.importQuakesUsingBIR(from: geoJSON)
                } else {
                    try self.importQuakesBeforeBIR(from: geoJSON)
                }
                print("\(Date()) Finished importing data.")
                
            } catch {
                // Alert the user if data cannot be digested.
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
        // Start the task.
        print("\(Date()) Start fetching data from server ...")
        task.resume()
    }
    
    /**
     Uses NSBatchInsertRequest (BIR) to import a JSON dictionary into the Core Data store on a private queue .
     NSBatchInsertRequest is available since iOS 13 and macOS 10.15.
    */
    @available(iOS 13, macOS 10.15, *)
    private func importQuakesUsingBIR(from geoJSON: GeoJSON) throws {
        guard !geoJSON.quakePropertiesList.isEmpty else { return }
        
        var performError: Error?

        // taskContext.performAndWait runs on the URLSession's delegate queue
        // so it won’t block the main thread.
        let taskContext = newTaskContext()
        taskContext.performAndWait {
            let batchInsert = self.newBatchInsertRequest(with: geoJSON.quakePropertiesList)
            batchInsert.resultType = .statusOnly
            
            if let batchInsertResult = try? taskContext.execute(batchInsert) as? NSBatchInsertResult,
                let success = batchInsertResult.result as? Bool, success {
                return
            }
            performError = QuakeError.batchInsertError
        }

        if let error = performError {
            throw error
        }
    }

    @available(iOS 13, macOS 10.15, *)
    private func newBatchInsertRequest(with quakeDictionaryList: [[String: Any]]) -> NSBatchInsertRequest {
        let batchInsert: NSBatchInsertRequest
        if #available(iOS 14, macOS 10.16, *) {
            // Provide one dictionary at a time when the block is called.
            var index = 0
            let total = quakeDictionaryList.count
            batchInsert = NSBatchInsertRequest(entityName: "Quake", dictionaryHandler: { dictionary in
                guard index < total else { return true }
                dictionary.addEntries(from: quakeDictionaryList[index])
                index += 1
                return false
            })
        } else {
            // Provide the dictionaries all together.
            batchInsert = NSBatchInsertRequest(entityName: "Quake", objects: quakeDictionaryList)
        }
        return batchInsert
    }
    
    /**
     Imports a JSON dictionary into the Core Data store on a private queue,
     processing the record in batches to avoid a high memory footprint.
    */
    private func importQuakesBeforeBIR(from geoJSON: GeoJSON) throws {
        guard !geoJSON.quakePropertiesList.isEmpty else { return }
                
        // Process records in batches to avoid a high memory footprint.
        let batchSize = 256
        let count = geoJSON.quakePropertiesList.count
        
        // Determine the total number of batches.
        var numBatches = count / batchSize
        numBatches += count % batchSize > 0 ? 1 : 0
        
        for batchNumber in 0 ..< numBatches {
            // Determine the range for this batch.
            let batchStart = batchNumber * batchSize
            let batchEnd = batchStart + min(batchSize, count - batchNumber * batchSize)
            let range = batchStart..<batchEnd
            
            // Create a batch for this range from the decoded JSON.
            // Stop importing if any batch is unsuccessful.
            try importOneBatch(Array(geoJSON.quakePropertiesList[range]))
        }
    }
    
    /**
     Imports one batch of quakes, creating managed objects from the new data,
     and saving them to the persistent store, on a private queue. After saving,
     resets the context to clean up the cache and lower the memory footprint.
     
     NSManagedObjectContext.performAndWait doesn't rethrow so this function
     catches throws within the closure and uses a return value to indicate
     whether the import is successful.
    */
    private func importOneBatch(_ quakeDictionaryBatch: [[String: Any]]) throws {
        let taskContext = newTaskContext()
        var performError: Error?
        
        // taskContext.performAndWait runs on the URLSession's delegate queue
        // so it won’t block the main thread.
        taskContext.performAndWait {
            // Create a new record for each quake in the batch.
            for quakeDictionary in quakeDictionaryBatch {
                // Create a Quake managed object on the private queue context.
                guard let quake = NSEntityDescription.insertNewObject(forEntityName: "Quake", into: taskContext) as? Quake else {
                    performError = QuakeError.creationError
                    return
                }
                
                // Populate the Quake's properties using the raw data.
                do {
                    try quake.update(with: quakeDictionary)
                } catch {
                    // QuakeError.missingData: Delete invalid Quake from the private queue context and continue.
                    print(QuakeError.missingData.localizedDescription)
                    taskContext.delete(quake)
                }
            }
            
            // Save all insertions and deletions from the context to the store.
            if taskContext.hasChanges {
                do {
                    try taskContext.save()
                } catch {
                    performError = error
                    return
                }
                // Reset the taskContext to free the cache and lower the memory footprint.
                taskContext.reset()
            }
        }
        
        if let error = performError {
            throw error
        }
    }
    
    /**
     Deletes all the records in the Core Data store.
    */
    func deleteAll(completionHandler: @escaping (Error?) -> Void) {
        let taskContext = newTaskContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Quake")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeCount
            
            // Execute the batch insert
            if let batchDeleteResult = try? taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult,
                batchDeleteResult.result != nil {
                completionHandler(nil)

            } else {
                completionHandler(QuakeError.batchDeleteError)
            }
        }
    }

    // MARK: - NSFetchedResultsController
    
    /**
     A fetched results controller delegate to give consumers a chance to update
     the user interface when content changes.
     */
    weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    
    /**
     A fetched results controller to fetch Quake records sorted by time.
     */
    lazy var fetchedResultsController: NSFetchedResultsController<Quake> = {
        
        // Create a fetch request for the Quake entity sorted by time.
        let fetchRequest = NSFetchRequest<Quake>(entityName: "Quake")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        fetchRequest.propertiesToFetch = ["magnitude", "place", "time"]
        // Create a fetched results controller and set its fetch request, context, and delegate.
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: persistentContainer.viewContext,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = fetchedResultsControllerDelegate
        
        // Perform the fetch.
        do {
            try controller.performFetch()
        } catch {
            fatalError("Unresolved error \(error)")
        }
        
        return controller
    }()
    
    /**
     Resets viewContext and refetches the data from the store.
     */
    func resetAndRefetch() {
        persistentContainer.viewContext.reset()
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }
    
    // MARK: - NSPersistentStoreRemoteChange handler

    /**
     Handles remote store change notifications (.NSPersistentStoreRemoteChange).
     storeRemoteChange runs on the queue where the changes were made.
     */
    @objc
    func storeRemoteChange(_ notification: Notification) {
        // print("\(#function): Got a persistent store remote change notification!")
    }
}
