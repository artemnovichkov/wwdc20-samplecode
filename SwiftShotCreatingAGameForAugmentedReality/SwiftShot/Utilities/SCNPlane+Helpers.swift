/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for SCNPlane size.
*/

import Foundation
import SceneKit

extension SCNPlane {
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
}
