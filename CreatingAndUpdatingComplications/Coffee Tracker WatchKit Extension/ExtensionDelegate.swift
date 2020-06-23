/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A delegate object for the WatchKit extension that implements the needed lifecycle methods.
*/

import WatchKit

// The app's extension delegate.
class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    // MARK: - Delegate Methods
    
    // Call when the app goes to the background.
    func applicationDidEnterBackground() {
        // Schedule a background refresh task to update the complications.
        scheduleBackgroundRefreshTasks()
    }
    
    // Download updates from HealthKit whenever the app enters the foreground.
    func applicationWillEnterForeground() {
        
        // Make sure the app has requested authorization.
        let model = CoffeeData.shared
        model.healthKitController.requestAuthorization { (success) in
            
            // Check for errors.
            if !success { fatalError("*** Unable to authenticate HealthKit ***") }
            
            // check for updates from HealthKit
            model.healthKitController.loadNewDataFromHealthKit {}
        }
    }

    // Called when a background task occurs.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            
            switch task {
            // Handle background refresh tasks.
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                
                // check for updates from HealthKit
                let model = CoffeeData.shared
                
                model.healthKitController.loadNewDataFromHealthKit {
                    // Schedule the next background update.
                    self.scheduleBackgroundRefreshTasks()
                    
                    // Mark the task as ended, and request an updated snapshot.
                    backgroundTask.setTaskCompletedWithSnapshot(true)
                }
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    // MARK: - Private Methods
    // Schedule the next background refresh task.
    func scheduleBackgroundRefreshTasks() {
        
        // Get the shared extension object.
        let watchExtension = WKExtension.shared()
        
        // If there is a complication on the watch face, the app should get at least four
        // updates an hour. So calculate a target date 15 minutes in the future.
        let targetDate = Date().addingTimeInterval(15.0 * 60.0)
        
        // Schedule the background refresh task.
        watchExtension.scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { (error) in
            
            // Check for errors.
            if let error = error {
                print("*** An background refresh error occurred: \(error.localizedDescription) ***")
                return
            }
            
            print("*** Background Task Completed Successfully! ***")
        }
    }
}
