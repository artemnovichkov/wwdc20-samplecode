/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the data types used to structure media in a sound library.
*/

import Foundation

public typealias LibraryItemID = UUID
public protocol LibraryItem {
    var itemID: LibraryItemID { get }
    var title: String { get }
}

/// A container of sound items.
public struct Soundscape: LibraryItem, Codable, Hashable, Equatable {
    
    public let itemID: LibraryItemID
    public let title: String
    public let containerName: String
    
    public let artworkName: String
}

/// An individual sound item part of a `Soundscape`.
public struct Track: LibraryItem, Codable, Equatable {
    
    public let itemID: LibraryItemID
    public let title: String
    let containerMembership: [LibraryItemID]
}

extension NSUserActivity {
    public static let LibraryItemContainerIDKey = "LibraryItemContainerID"
}
