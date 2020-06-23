/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Coffee model.
*/

import UIKit

struct Coffee {
    let brand: String
    let caption: String
    let image: UIImage?
    let roast: Roast
    let price: String
    let tastingNotes: [TastingNotes]

    enum Roast: String {
        case light
        case medium
        case dark
    }

    enum TastingNotes: String {
        case chocolatey
        case bitter
        case smooth
        case earthy
        case bright
        case sour
        case nutty
        case sweet
    }
}

extension Coffee {
    var tags: String {
        return tastingNotes.map { $0.rawValue }.joined(separator: " • ")
    }
}
