/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app delegate.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // MARK: Menu builder and global keyboard shortcuts
    
    override func buildMenu(with builder: UIMenuBuilder) {
        let newItemCommand = UIKeyCommand(
            input: "n",
            modifierFlags: .command,
            action: #selector(GlobalKeyboardShortcutRespondable.createNewItem)
        )
        
        newItemCommand.title = NSLocalizedString("NEW", comment: "Create new item discoverability title")
        
        // Key command for deleteSelectedItem
        let deleteSelectedItemCommand = UIKeyCommand(
            title: NSLocalizedString("DELETE", comment: "Delete discoverability title"),
            action: #selector(GlobalKeyboardShortcutRespondable.deleteSelectedItem),
            input: "\u{8}" // This is the backspace character represented as a Unicode scalar
        )

        builder.replaceChildren(ofMenu: .standardEdit) { children in
            return [ newItemCommand, deleteSelectedItemCommand ] + children
        }
    }
}

