/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility extension on `UIImageView` for visual appearance.
*/

import UIKit

extension UIImageView {
    public func applyRoundedCorners() {
        layer.cornerRadius = 8
        clipsToBounds = true
    }
}
