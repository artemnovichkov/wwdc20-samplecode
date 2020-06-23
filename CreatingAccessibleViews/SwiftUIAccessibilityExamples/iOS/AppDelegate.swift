/*
See LICENSE folder for this sample’s licensing information.

Abstract:
iOS App Delegate for accessibility examples
*/

import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: AccessibilityExamplesView())
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

