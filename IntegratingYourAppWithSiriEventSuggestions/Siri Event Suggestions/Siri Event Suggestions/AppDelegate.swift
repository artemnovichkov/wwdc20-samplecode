/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import Intents

extension Notification.Name {
    static let showReservation = Notification.Name("ShowReservation")
    static let startReservationCheckIn = Notification.Name("StartReservationCheckIn")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        // Your app was launched with the INGetReservationDetailsIntent intent. You should reconfigure your UI
        // to display the reservations specified in the intent.
        if userActivity.activityType == "INGetReservationDetailsIntent" {
            let notification = Notification(name: .showReservation, object: userActivity, userInfo: nil)
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(notification)
            return true
        }
        // Your app was launched with the custom "com.example.apple-samplecode.Siri-Event-Suggestions.check-in" activity type
        // that is specified for the check-in action. You should reconfigure your UI to start the check-in flow.
        else if userActivity.activityType == "com.example.apple-samplecode.Siri-Event-Suggestions.check-in" {
            let notification = Notification(name: .startReservationCheckIn, object: userActivity, userInfo: nil)
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(notification)
            return true
        }
        return false
    }
}

