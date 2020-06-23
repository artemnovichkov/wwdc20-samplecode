# Loading and Displaying a Large Data Feed

Consume data in the background, and lower memory usage by batching imports and preventing duplicate records.

## Overview
This sample creates an app that shows a list of earthquakes recorded in the United States in the past 30 days by consuming a U. S. Geological Survey (USGS) real-time data feed.

Press the app’s refresh button to load the USGS JSON feed on the URLSession’s default delegate queue, which is an operation queue that runs in the background. Once the feed downloads, the app continues working on this queue to import the large number of feed elements to the store without blocking the main queue.

- Note: This sample code project is associated with WWDC20 session [10017: Core Data: Sundries and Maxims](https://developer.apple.com/wwdc20/10017/).

## Import Data in the Background

To import data in the background, apps need two managed object contexts ([`NSManagedObjectContext`](https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext)): a main queue context to provide data to the user interface, and a private queue context to perform the import on a background queue. Both contexts are connected to the same [`persistentStoreCoordinator`](https://developer.apple.com/documentation/coredata/nspersistentcontainer/1640567-persistentstorecoordinator). This configuration is more efficient than using a nested context.

The sample creates a main queue context by setting up a Core Data stack using [`NSPersistentContainer`](https://developer.apple.com/documentation/coredata/nspersistentcontainer), which initializes a main queue context in its [`viewContext`](https://developer.apple.com/documentation/coredata/nspersistentcontainer/1640622-viewcontext) property. 

``` swift
let container = NSPersistentContainer(name: "Earthquakes")
```

Create a private queue context by calling the persistent container’s [`newBackgroundContext()`](https://developer.apple.com/documentation/coredata/nspersistentcontainer/1640581-newbackgroundcontext) method.

``` swift
let taskContext = persistentContainer.newBackgroundContext()
```

When the feed download finishes, the sample uses the task context to consume the feed in the background. In Core Data, every queue-based context has its own serial queue, and apps must serialize the tasks that manipulate the context with the queue by wrapping the code with a [`perform()`](https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext/1506578-perform) 
or [`performAndWait()`](https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext/1506364-performandwait) closure.

``` swift
// taskContext.performAndWait runs on the URLSession's delegate queue
// so it won’t block the main thread.
taskContext.performAndWait {
```

For more information about working with concurrency, see [`NSManagedObjectContext`](https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext#1654001).

To efficiently handle large data sets, the sample uses [`NSBatchInsertRequest`](https://developer.apple.com/documentation/coredata/nsbatchinsertrequest) which accesses the store directly without interacting with the context, triggering any key value observation, or loading data into memory. The closure-style initializer of `NSBatchInsertRequest` allows apps to provide one record at a time when Core Data calls the `dictionaryHandler` closure, which helps apps keep their memory footprint low because they don't need to prepare a buffer for all records.

``` swift
let batchInsert = self.newBatchInsertRequest(with: geoJSON.quakePropertiesList)
batchInsert.resultType = .statusOnly

if let batchInsertResult = try? taskContext.execute(batchInsert) as? NSBatchInsertResult,
    let success = batchInsertResult.result as? Bool, success {
    return
}
```

## Update the User Interface

Because `NSBatchInsertRequest` bypasses the context and doesn't trigger `NSManagedObjectContextDidSavenotification`, apps that need to update the UI with the changes have two options:
-  Extract the relevant changes by parsing the store's [`persistent history`](https://developer.apple.com/documentation/coredata/persistent_history), then merge them to the context. See [`Consuming Relevant Store Changes`](https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes) for more details.
- Reset the context and re-fetch data from the store. 

This sample resets the context and fetches the data from the store because:
- All the results are presented in one table, with no unique processing needed for any particular elements.
- Core Data only fetches a small part of the data set, which is appropriate for current use. When the user scrolls the table, more data is fetched.

``` swift
persistentContainer.viewContext.reset()
do {
    try fetchedResultsController.performFetch()
} catch {
    fatalError("Unresolved error \(error)")
}
```

After executing `NSBatchInsertRequest`, the sample dispatches any user-interface state updates back to the main queue.

``` swift
dataProvider.fetchQuakes { error in
    DispatchQueue.main.async {
        self.exitBusyUI()
        // Alert the error or refresh the table if no error.
        self.handleBatchOperationCompletion(error: error)
    }
}
```

## Work in Batches to Lower Memory Footprint

Core Data caches the objects that apps fetch or create in a context to avoid a round trip to the store file when these objects are needed again. However, that approach grows the memory footprint of an app as it processes more and more objects, and can eventually lead to low-memory warnings or app termination on iOS.

`NSBatchInsertRequest` doesn't obviously increase an app's memory footprint because it doesn't load data into memory. Apps targeted to run on a system earlier than iOS 13 or macOS 10.15 need to avoid memory footprint growing by processing the objects in batches and calling [`reset()`](https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext/1506807-reset) to reset the context after each batch. In the sample, these two cases are demonstrated in the `importQuakesUsingBIR(from:)` and `importQuakesBeforeBIR(from:)` method respectively.

The sample sets the `viewContext`’s [`automaticallyMergesChangesFromParent`](https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext/1845237-automaticallymergeschangesfrompa) property to `false` to prevent Core Data from automatically merging changes every time the background context is saved.

``` swift
container.viewContext.automaticallyMergesChangesFromParent = false
```

## Prevent Duplicate Data in the Store

Every time the sample app refreshes the feed, the data downloaded from the remote server contains all earthquake records for the past month, so it can have many duplicates of already imported data. To avoid creating duplicate records, the app constrains an attribute, or combination of attributes, to be unique across all instances. 

The `code` attribute uniquely identifies an earthquake record, so constraining the `Quake` entity on `code` ensures that no two stored records have the same `code` value.

Select the `Quake` entity in the data model editor. In the data model inspector, add a new constraint by clicking the + button under the Constraints list. A constraint placeholder appears.

```
comma, separated, properties
```

Double-click the placeholder to edit it. Enter the name of the attribute (or comma-separated list of attributes) to serve as unique constraints on the entity. 

```
code
```

When saving a new record, the store now checks whether any record already exists with the same value for the constrained attribute. In the case of a conflict, an [`NSMergeByPropertyObjectTrump`](https://developer.apple.com/documentation/coredata/nsmergebypropertyobjecttrumpmergepolicy) policy comes into play, and the new record overwrites all fields in the existing record.
