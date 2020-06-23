/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A struct representing media content the user has requested to play.
*/

import Foundation

/// A struct representing media content the user has requested to play.
public struct PlayRequest: Codable {
    public let container: Soundscape
    public let tracks: [Track]?
    
    public init(container: Soundscape, tracks: [Track]?) {
        self.container = container
        self.tracks = tracks
    }
}
