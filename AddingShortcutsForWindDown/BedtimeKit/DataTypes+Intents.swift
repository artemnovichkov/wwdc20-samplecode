/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility file that converts the struct types representing media into equivalent representations
 for use with the Intents framework.
*/

import Foundation
import Intents

protocol MediaItemConvertible {
    var mediaItem: INMediaItem { get }
}

extension Soundscape: MediaItemConvertible {
    
    var mediaItem: INMediaItem {
        return INMediaItem(identifier: itemID.uuidString,
                           title: title,
                           type: .station,
                           artwork: INImage(named: artworkName))
    }
}

extension Track: MediaItemConvertible {
    
    var mediaItem: INMediaItem {
        return INMediaItem(identifier: itemID.uuidString,
                           title: title,
                           type: .music,
                           artwork: nil)
    }
}

extension PlayRequest {
    
    public var intent: INPlayMediaIntent {
        let mediaItems = tracks?.map { $0.mediaItem }
        let intent = INPlayMediaIntent(mediaItems: mediaItems,
                                       mediaContainer: container.mediaItem,
                                       playShuffled: false,
                                       playbackRepeatMode: .none,
                                       resumePlayback: false)
        /*
         Set the shortcutAvailability property to be sleepMusic so that this donation
         will show up in the Wind Down setup flow in the Health app.
         */
        intent.shortcutAvailability = .sleepMusic
        /*
         Set the suggestedInvocationPhrase property to the track title if a single track was played.
         */
        if let track = tracks?.first, tracks?.count == 1 {
            intent.suggestedInvocationPhrase = "Play \(track.title)"
        }
        
        return intent
    }
    
    public init?(intent: INPlayMediaIntent) {
        
        let libraryManager = SoundLibraryDataManager.shared
        
        guard let container = intent.mediaContainer,
            let containerID = container.identifier,
            let libraryContainerID = LibraryItemID(uuidString: containerID),
            let libraryContainer = libraryManager.container(matching: libraryContainerID)
        else {
            return nil
        }
        
        // Find unplayed tracks.
        let unplayedTracks = intent.mediaItems?.compactMap { (item) -> Track? in
            guard let trackID = item.identifier,
                let libraryItemID = LibraryItemID(uuidString: trackID)
            else {
                return nil
            }
            
            return libraryManager.track(matching: libraryItemID)
        }
        
        self = PlayRequest(container: libraryContainer, tracks: unplayedTracks)
    }
}
