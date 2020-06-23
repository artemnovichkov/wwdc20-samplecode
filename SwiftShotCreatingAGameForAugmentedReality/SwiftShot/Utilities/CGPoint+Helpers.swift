/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helpers for CGPoint
*/

import UIKit

extension CGPoint {
    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}
