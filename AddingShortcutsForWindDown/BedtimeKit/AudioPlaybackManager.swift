/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`AudioPlaybackManager` is a singleton object which manages the audio playback state for the app,
 including the audio session, audio player, and queue of items to play.
*/

import Foundation
import AVFoundation
import MediaPlayer
import Intents
import os.log

/// A single entry in the play queue, pairing a track to play with the container it is playing from.
public typealias PlayQueueItem = (container: Soundscape, track: Track)

/// `AudioPlaybackManager` manages the audio playback state for the app, including the audio session,
/// audio player, and queue of items to play.
public class AudioPlaybackManager: NSObject {
    
    /// Singleton instance of `AudioPlaybackManager`.
    public static let shared = AudioPlaybackManager()
    
    private var player: AVAudioPlayer?
    
    private var playQueue = [PlayQueueItem]()
    private var playingRequest: PlayQueueItem?
    private let audioManagerQueue = DispatchQueue(label: "Audio Manager Queue")
    
    private var libraryManager = SoundLibraryDataManager.shared
    
    private static var audioFile = Bundle(for: AudioPlaybackManager.self).url(forResource: "Synth", withExtension: "aif")!
    private static var audioFileDuration: TimeInterval {
        let audioAsset = AVURLAsset(url: audioFile)
        return audioAsset.duration.seconds
    }
    
    private var enabledAudioCommands = [MPRemoteCommand]()
    
    /// Takes a `PlayRequest` and transforms it into an array of specific items that can be played.
    /// This allows clients about to start playing content a chance to verify there is content to play and
    /// inspect the data for the content about to play, such as to pass it to other parts of the system for display.
    public func resolveItems(for request: PlayRequest) -> [PlayQueueItem]? {
        // Ensure the container is still available in the library
        guard let container = libraryManager.container(matching: request.container.itemID) else { return nil }
        
        // If the request didn't contain specific tracks to play, play everything currently in the library for that container.
        let requestedTracks = request.tracks ?? libraryManager.tracks(for: request.container.itemID)
        return requestedTracks.map { (track) -> PlayQueueItem in
            return (container, track)
        }
    }
    
    /// Starts playback of items in the request array. If playback of existing requests are in progress,
    /// playback is stopped and the existing queue is replaced with the new requests.
    /// - Parameter items: An array of `PlayQueueItem` created by calling `resolveItems(for:)` with a `PlayRequest`
    public func play(_ items: [PlayQueueItem]) {
        stopPlaying()
        audioManagerQueue.sync {
            if player == nil {
                createPlayer()
            }
            playQueue = items
            playNextItem()
        }
    }
    
    /// Stops audio playback
    public func stopPlaying() {
        audioManagerQueue.sync {
            player?.stop()
            stopAudioControl()
            player = nil
        }
    }
    
    /// Called by the audio session delegate to play the next item in the play queue.
    private func playNextItem() {
        playingRequest = playQueue.first
        
        if playingRequest != nil {
            startAudioControl()
        } else {
            stopAudioControl()
        }
        
        if playingRequest != nil {
            player?.play()
        }
        
        updateNowPlayingCenter()
    }
    
    /// Called by the audio session delegate to mark the currently playing item as played.
    private func completePlaybackOfCurrentItem() {
        playQueue.removeFirst()
        playingRequest = nil
    }
    
    private func updateNowPlayingCenter() {
        DispatchQueue.main.async { [weak self] in
            let infoCenter = MPNowPlayingInfoCenter.default()
            
            if let playingItem = self?.playingRequest {
                infoCenter.nowPlayingInfo = AudioPlaybackManager.nowPlayingInfo(for: playingItem.track, in: playingItem.container)
            } else {
                infoCenter.nowPlayingInfo = nil
            }
        }
    }
    
    /// Sets up the audio session and provides remote control event handling.
    private func startAudioControl() {
        guard enabledAudioCommands.isEmpty else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch let error as NSError {
            os_log("Could not set up audio session. %@", log: OSLog.default, type: .error, error)
        }
        
        let toggleCommand = MPRemoteCommandCenter.shared().togglePlayPauseCommand
        toggleCommand.isEnabled = true
        toggleCommand.addTarget { [weak self] (_) -> MPRemoteCommandHandlerStatus in
            guard let audioPlayer = self?.player else { return .commandFailed }
            
            if audioPlayer.isPlaying {
                audioPlayer.pause()
            } else {
                audioPlayer.play()
            }
            return .success
        }
        enabledAudioCommands.append(toggleCommand)
    }
    
    /// Stops the audio session and removes remote control event hooks.
    private func stopAudioControl() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            player?.stop()
            try audioSession.setActive(false)
        } catch let error as NSError {
            os_log("Could not set up audio session. Reason: %@", log: OSLog.default, type: .error, error)
        }
        
        for command in enabledAudioCommands {
            command.isEnabled = false
            command.removeTarget(nil)
        }
        
        enabledAudioCommands.removeAll()
    }
    
    private func createPlayer() {
        do {
            player = try AVAudioPlayer(contentsOf: AudioPlaybackManager.audioFile)
            player?.delegate = self
        } catch let error as NSError {
            os_log("Could not create audio player. Reason: %@", log: OSLog.default, type: .error, error)
        }
    }
    
    /// - Returns: Dictionary of MPMediaItemProperty keys with values for the media passed as parameters
    public static func nowPlayingInfo(for track: Track, in container: Soundscape, forShortcut: Bool = false) -> [String: Any] {
        var nowPlayingInfo: [String: Any] = [MPMediaItemPropertyTitle: track.title,
                                             MPMediaItemPropertyMediaType: MPMediaType.anyAudio.rawValue,
                                             MPMediaItemPropertyAlbumTitle: container.title,
                                             MPMediaItemPropertyPlaybackDuration: NSNumber(value: audioFileDuration)]
        
        if forShortcut {
            // The now playing info set on an INPlayMediaIntentResponse needs to use an INImage.
            nowPlayingInfo[MPMediaItemPropertyArtwork] = INImage(named: container.artworkName)
        } else {
            if let image = UIImage(named: container.artworkName) {
                let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 60, height: 60)) { (_) -> UIImage in
                    return image
                }
                
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
        }
        
        return nowPlayingInfo
    }
}

extension AudioPlaybackManager: AVAudioPlayerDelegate {

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioManagerQueue.sync {
            completePlaybackOfCurrentItem()
            playNextItem()
        }
    }
}
