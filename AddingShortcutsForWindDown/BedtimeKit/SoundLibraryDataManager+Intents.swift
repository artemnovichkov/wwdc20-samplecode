/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension to `SoundLibraryDataManager` to group all functionality related to the Intents framework together.
*/

import Foundation
import Intents
import os.log

extension SoundLibraryDataManager {
    
    /// Provides shortcuts for featured soundscapes the user may want to play.
    /// The results of this method are visible in the Health app.
    func updateBedtimeShortcutSuggestions() {
        let newMediaIntents = soundLibrary.soundscapes.reduce([INShortcut]()) { (partialResult, container) -> [INShortcut] in
            let playMediaIntent = INPlayMediaIntent(mediaItems: nil,
                                                    mediaContainer: container.mediaItem,
                                                    playShuffled: false,
                                                    playbackRepeatMode: .none,
                                                    resumePlayback: false)
            playMediaIntent.shortcutAvailability = .sleepMusic
            playMediaIntent.suggestedInvocationPhrase = "Play \(container.containerName)"
            guard let mediaShortcut = INShortcut(intent: playMediaIntent) else { return partialResult }
            let results = partialResult + [mediaShortcut]
            return results
        }
        
        INVoiceShortcutCenter.shared.setShortcutSuggestions(newMediaIntents)
    }
        
    /// Inform the system of what media the user asked to play.
    public func donatePlayRequestToSystem(_ request: PlayRequest) {
        let interaction = INInteraction(intent: request.intent, response: nil)
        
        /*
         Set the groupIdentifier to be the container's ID so that all interactions can be
         deleted with the same ID if the user deletes the container.
         */
        interaction.groupIdentifier = request.container.itemID.uuidString
        
        interaction.donate { (error) in
            if error != nil {
                guard let error = error as NSError? else { return }
                os_log("Could not donate interaction %@", error)
            } else {
                os_log("Play request interaction donation succeeded")
            }
        }
    }
}
