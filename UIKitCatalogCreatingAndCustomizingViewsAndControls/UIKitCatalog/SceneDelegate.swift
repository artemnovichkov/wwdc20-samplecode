/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class demonstrates how to use the scene delegate to configure a scene's interface.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?
        
    /** Applications should configure their UIWindow, and attach the UIWindow to the provided UIWindowScene scene.
 
        Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
     
        If using a storyboard file (as specified by the Info.plist key, UISceneStoryboardFile,
        the window property will automatically be configured and attached to the windowScene.
 
        Remember to retain the SceneDelegate 's UIWindow.
        The recommended approach is for the SceneDelegate to retain the scene's window.
    */
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let splitViewController = window!.rootViewController as? UISplitViewController {
            splitViewController.delegate = self
            splitViewController.preferredDisplayMode = .oneBesideSecondary
        }
    }

    /** Called as the scene is being released by the system or on window close.
        This occurs shortly after the scene enters the background, or when its session is discarded.
        Release any resources associated with this scene that can be re-created the next time the scene connects.
        The scene may re-connect later, as its session was not neccessarily discarded (see`application:didDiscardSceneSessions` instead).
    */
    func sceneDidDisconnect(_ scene: UIScene) {
    }
    
    /** Called as the scene transitions from the background to the foreground,
        on window open or in iOS resume.
        Use this method to undo the changes made on entering the background.
    */
    func sceneWillEnterForeground(_ scene: UIScene) {
    }
    
    /** Called as the scene transitions from the foreground to the background.
        Use this method to save data, release shared resources, and store enough scene-specific state information
        to restore the scene back to its current state.
     */
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
    
    /** Called when the scene "will move" from an active state to an inactive state,
        on window close or in iOS enter background.
        This may occur due to temporary interruptions (ex. an incoming phone call).
    */
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    /** Called when the scene "has moved" from an inactive state to an active state.
        Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        Is called every time a scene becomes active, so setup your scene UI here.
    */
    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        // Return true to prevent UIKit from applying its default behavior.
        return true
    }
}
