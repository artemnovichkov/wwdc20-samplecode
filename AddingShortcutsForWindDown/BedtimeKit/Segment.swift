/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A struct representing an track in the sound library.
*/

import Foundation

public struct Track: LibraryItem, Codable, Equatable {
    
    public let itemID: LibraryItemID
    public let title: String
    let containerMembership: [LibraryItemID]
}
