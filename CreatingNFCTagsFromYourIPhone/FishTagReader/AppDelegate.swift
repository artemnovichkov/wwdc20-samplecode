/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main application delegate.
*/

import UIKit
import CoreNFC

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        // You handle the user activity created by the NFC background tag reading feature.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return false
        }
        
        // Confirm that the NSUserActivity object contains a valid NDEF message.
        let ndefMessage = userActivity.ndefMessagePayload
        guard !ndefMessage.records.isEmpty,
            ndefMessage.records[0].typeNameFormat != .empty else {
                return false
        }
        
        guard let scanViewController = window?.rootViewController as? ScanViewController else {
            fatalError("")
        }
        
        DispatchQueue.main.async {
            // You send the message to `ScanViewController` for processing.
            _ = scanViewController.updateWithNDEFMessage(ndefMessage)
        }
        
        return true
    }
}

