/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for the application.
*/

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var deviceTokenLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    public func showDeviceToken(_ tokenString: String) {
        deviceTokenLabel.text = "Device Token: \n\(tokenString)"
    }

    public func updateMenu(withData data: Data) {
        // update menu here
    }

}

