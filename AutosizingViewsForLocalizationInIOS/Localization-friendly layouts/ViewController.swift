/*
See LICENSE folder for this sample’s licensing information.

Abstract:

*/

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var buttons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // To enable our button labels to automatically adjust to dynamic type settings changes,
        // we have to set `adjustsFontForContentSizeCategory` to `true`.
        buttons.forEach { (button) in
            button.titleLabel?.adjustsFontForContentSizeCategory = true
        }
    }
}

