/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The AppDelegate.
*/
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        return true
    }

}

// MARK: - UIMenu

extension Notification.Name {
    static let shareMenuActivated = Notification.Name(rawValue: "shareMenuActivated")
}

extension AppDelegate {

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        /*
         When adding a keyboard shortcut, we first check to see a standard keycode exists
         https://developer.apple.com/design/human-interface-guidelines/macos/user-interaction/keyboard

         In this case, share is not one of them. Next we would check existing applications
         to see of they have a similar shortcut. In this cases, Safari uses the "I" key
         with the command modifier, so we can mirror that in our app.
        */
        let shareCommand =
            UIKeyCommand(title: NSLocalizedString("Share", comment: ""),
                         action: #selector(Self.handleShareMenuAction),
                         input: "I",
                         modifierFlags: [.command])
        let shareMenu =
            UIMenu(title: "",
                   identifier: UIMenu.Identifier("com.example.apple-samplecode.RoastedBeans.share"),
                   options: .displayInline,
                   children: [shareCommand])
        builder.insertChild(shareMenu, atEndOfMenu: .edit)
    }

    @objc
    func handleShareMenuAction() {
        NotificationCenter.default.post(Notification(name: .shareMenuActivated))
    }

}
