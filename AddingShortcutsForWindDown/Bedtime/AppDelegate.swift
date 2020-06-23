/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate, which handles content playback through continuing user activity or handling an intent.
*/

import UIKit
import Intents
import BedtimeKit

@UIApplicationMain
class AppDelegate: UIResponder {

    var window: UIWindow?
    var audioManager: AudioPlaybackManager?
}

extension AppDelegate: UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        // If a user taps on the UI for a media suggestion, the app will open and the media suggestion will be
        // delivered to the app within a NSUserActivity. The activity type string on the activity will be the
        // name of the intent.
        
        guard userActivity.activityType == NSStringFromClass(INPlayMediaIntent.self),
            let mediaIntent = userActivity.interaction?.intent as? INPlayMediaIntent,
            let requestedContent = PlayRequest(intent: mediaIntent),
            let navigationController = window?.rootViewController as? UINavigationController
        else {
            return false
        }
        
        // Continuing a user activity should display the content rather than start playback of the content. Pass the
        // user activity to a view controller for display.
        userActivity.addUserInfoEntries(from: [NSUserActivity.LibraryItemContainerIDKey: requestedContent.container.itemID])
        restorationHandler(navigationController.viewControllers)
        
        return true
    }
    
    func application(_ application: UIApplication, handle intent: INIntent, completionHandler: @escaping (INIntentResponse) -> Void) {
        // If a user taps on the play button for a media suggestion, the app will deliver an intent to the intent extension,
        // and if the extension indicates the app can handle the intent, it will be delivered to this method to start playback.
        
        guard let mediaIntent = intent as? INPlayMediaIntent,
            let requestedContent = PlayRequest(intent: mediaIntent),
            let itemsToPlay = AudioPlaybackManager.shared.resolveItems(for: requestedContent)
        else {
            completionHandler(INPlayMediaIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        AudioPlaybackManager.shared.play(itemsToPlay)
        
        let response = INPlayMediaIntentResponse(code: .success, userActivity: nil)
        completionHandler(response)
    }
}
