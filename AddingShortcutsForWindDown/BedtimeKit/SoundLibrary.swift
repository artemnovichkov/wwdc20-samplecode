/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Defines the structure of the audio library.
*/

import Foundation

public struct SoundLibrary: Codable {
    public var soundscapes: [Soundscape]
    public var tracks: [Track]
    
    init() {
        soundscapes = []
        tracks = []
    }
}
