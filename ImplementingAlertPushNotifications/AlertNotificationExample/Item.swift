/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A menu item that a customer can purchase.
*/

import Foundation

class Item {
    var name: String
    var price: Float

    init(name: String, price: Float) {
        self.name = name
        self.price = price
    }
}
