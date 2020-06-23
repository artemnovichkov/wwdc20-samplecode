/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Status model.
*/

import Foundation

enum Status {
    case unpurchased
    case purchased(rating: Rating?)
    
    enum Rating: Int {
        case veryNotGood = 1
        case notGood = 2
        case moderate = 3
        case good = 4
        case veryGood = 5
    }
}

extension Status {
    var rating: Rating? {
        switch self {
        case .unpurchased:
            return nil
        case .purchased(let rating):
            return rating
        }
    }
}

