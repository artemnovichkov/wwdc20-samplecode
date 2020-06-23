/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`PencilKitDrawNavigationController` turns off the navigation bar background as it will affect latency.
*/

import UIKit

class PencilKitDrawNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        updateNavigationBarBackground()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateNavigationBarBackground()
    }
    
    func updateNavigationBarBackground() {
        // Turn off the navigation bar background as it will affect latency.
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIColor.secondarySystemBackground.withAlphaComponent(0.95).set()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: 1)).fill()
        navigationBar.setBackgroundImage(UIGraphicsGetImageFromCurrentImageContext(), for: .default)
        UIGraphicsEndImageContext()
    }
}
