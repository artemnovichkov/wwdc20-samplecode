/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data manager for the `SoundLibrary` struct.
*/

import Foundation

public class SoundLibraryDataManager {
    
    public static let shared = SoundLibraryDataManager()
    
    public let soundLibrary: SoundLibrary
    
    private init() {
        let bundle = Bundle(for: AudioPlaybackManager.self)
        var library = SoundLibrary()
        if let starterData = bundle.url(forResource: "StarterData", withExtension: "plist") {
            do {
                let data = try Data(contentsOf: starterData)
                let decoder = PropertyListDecoder()
                library = try decoder.decode(SoundLibrary.self, from: data)
                
            } catch let error {
                fatalError("Could not seed starter data from StarterData.plist. Reason: \(error)")
            }
        }
        soundLibrary = library
        updateBedtimeShortcutSuggestions()
    }
}

/// Public API for clients of `LibraryDataManager`.
extension SoundLibraryDataManager {
    
    /// Finds the matching container in the library.
    public func container(matching searchID: LibraryItemID) -> Soundscape? {
        return soundLibrary.soundscapes.first { (container) -> Bool in
            container.itemID == searchID
        }
    }

    /// Retrieves all tracks that are available for a soundscape container.
    public func tracks(for container: LibraryItemID) -> [Track] {
        return soundLibrary.tracks.filter { (track) -> Bool in
            track.containerMembership.contains(container)
        }
    }
    
    /// - Returns: A track with the matching identifier.
    public func track(matching trackID: LibraryItemID) -> Track? {
        return soundLibrary.tracks.first { (track) -> Bool in
            trackID == track.itemID
        }
    }
}
