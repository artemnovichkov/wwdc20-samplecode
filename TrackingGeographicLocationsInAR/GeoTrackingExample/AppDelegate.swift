/*
See LICENSE folder for this sample’s licensing information.

Abstract:
App delegate.
*/

import UIKit
import ARKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /* Check whether the device supports geo tracking. Present
         an error-message view controller, if not. */
        if !ARGeoTrackingConfiguration.isSupported {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "unsupportedDeviceMessage")
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if let viewController = self.window?.rootViewController as? ViewController {
            viewController.parseGPXFile(with: url)
            return true
        } else {
            return false
        }
    }
}

