/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for the application.
*/

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var deviceTokenLabel: UILabel!

    public var itemsInCart: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func subscribeToNotifications(_ sender: Any) {
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            print("Permission granted: \(granted)")
        }
    }

    public func showDeviceToken(_ tokenString: String) {
        deviceTokenLabel.text = "Device Token: \n\(tokenString)"
    }

}
