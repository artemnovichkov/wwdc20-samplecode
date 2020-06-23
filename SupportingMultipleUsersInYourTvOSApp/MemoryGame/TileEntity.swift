/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A set of utilities for manipulating TileEntity objects.
*/

import CoreData

extension TileEntity: Identifiable {
    var wrappedPosition: Int {
        get {
            Int(position)
        }

        set {
            position = Int64(newValue)
        }
    }

    var wrappedSticker: String {
        get {
            sticker ?? "missing sticker name"
        }

        set {
            sticker = newValue
        }
    }
}
