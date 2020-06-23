/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension for the smoothie model that offers an image property for ease of use.
*/

import SwiftUI

// MARK: - SwiftUI.Image
extension Smoothie {
    var image: Image {
        Image("smoothie/\(id)", label: Text(title))
            .renderingMode(.original)
    }
}
