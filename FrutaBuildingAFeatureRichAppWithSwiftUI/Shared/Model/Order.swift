/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A representation of an order — how many points it is worth and whether it is ready to be picked up.
*/

struct Order {
    private(set) var smoothie: Smoothie
    private(set) var points: Int
    var isReady: Bool
}
