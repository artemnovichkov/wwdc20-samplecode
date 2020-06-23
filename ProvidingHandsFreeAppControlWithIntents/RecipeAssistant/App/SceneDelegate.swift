/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application scene delegate.
*/

import UIKit
import Intents

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    // This method will be called when the app responds with .continueInApp
    // when it has no connected scenes
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        for userActivity in connectionOptions.userActivities {
            handleUserActivity(userActivity)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }

}

extension SceneDelegate {
    
    func handleUserActivity(_ userActivity: NSUserActivity) {
        guard let window = window,
            let rootViewController = window.rootViewController as? UINavigationController,
            let interaction = userActivity.interaction else {
                return
        }
        
        if let intent = interaction.intent as? ShowDirectionsIntent,
           let recipe = intent.recipe,
           let viewController = rootViewController.viewControllers.last as? NextStepProviding {
            viewController.nextStep(recipe: recipe)
        }
    }
    
}
