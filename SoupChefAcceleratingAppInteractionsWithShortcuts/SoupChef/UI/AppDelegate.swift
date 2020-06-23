/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import SoupKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        guard userActivity.activityType == NSStringFromClass(OrderSoupIntent.self) ||
            userActivity.activityType == NSUserActivity.viewMenuActivityType ||
            userActivity.activityType == NSUserActivity.orderCompleteActivityType else {
            os_log("Can't continue unknown NSUserActivity type %@", userActivity.activityType)
            return false
        }
        
        guard let window = window,
            let rootViewController = window.rootViewController as? UINavigationController else {
                os_log("Failed to access root view controller.")
                return false
        }
        
        // The `restorationHandler` passes the user activity to the passed in view controllers to route the user to the part of the app
        // that is able to continue the specific activity. See `restoreUserActivityState` in `OrderHistoryTableViewController`
        // to follow the continuation of the activity further.
        restorationHandler(rootViewController.viewControllers)
        return true
    }
}
