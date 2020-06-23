/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import Intents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        guard intent is ShowDirectionsIntent else {
            return nil
        }
        
        // Each view controller in this app assigns the current intent handler in `viewDidAppear`.
        //
        // If the app doesn't have any UIScenes connected to it, the `currentIntentHandler` will be `nil`,
        // so we need to create a new intent handler.
        return AppIntentHandler.shared.currentIntentHandler ?? IntentHandler()
    }
    
    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

}
