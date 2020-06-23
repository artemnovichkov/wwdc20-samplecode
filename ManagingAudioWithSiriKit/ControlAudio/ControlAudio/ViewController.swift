/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file implements methods for managing updating the UI state via MediaPlayer notifications
*/
import UIKit
import MediaPlayer

class ViewController: UIViewController {

    @IBOutlet private weak var playPauseButton: UIButton?
    @IBOutlet private weak var skipBackwardsButton: UIButton?
    @IBOutlet private weak var skipForwardsButton: UIButton?
    @IBOutlet private weak var songName: UILabel?
    @IBOutlet private weak var albumAndArtistName: UILabel?
    @IBOutlet private weak var albumArt: UIImageView?

    private var playbackStateDidChangeObserver: NSObjectProtocol?
    private var nowPlayingItemDidChangeObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Observe the system music player to keep the UI in sync.
        let player = MPMusicPlayerController.systemMusicPlayer
        let notificationCenter = NotificationCenter.default

        playbackStateDidChangeObserver = notificationCenter.addObserver(forName: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
                                                                        object: player, queue: OperationQueue.main) { notification in
            self.updatePlaybackState()
        }

        nowPlayingItemDidChangeObserver = notificationCenter.addObserver(forName: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                                                                         object: player, queue: OperationQueue.main) { notification in
            self.updateMediaItemState()
        }

        // Update based on the current state prior to beginning notifications.
        updatePlaybackState()
        updateMediaItemState()

        player.beginGeneratingPlaybackNotifications()
    }
    
    func updatePlaybackState() {
        let playbackState = MPMusicPlayerController.systemMusicPlayer.playbackState

        if playbackState == .playing {
            playPauseButton?.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        } else {
            playPauseButton?.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        }
    }

    func updateMediaItemState() {
        let mediaItem = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem

        if mediaItem == nil {
            songName?.text = nil
            albumAndArtistName?.text = nil
            albumArt?.image = nil
        } else {
            songName?.text = mediaItem?.title

            if let albumName = mediaItem?.albumTitle, let artistName = mediaItem?.artist {
                albumAndArtistName?.text = "\(albumName) - \(artistName)"
            } else if let artistName = mediaItem?.artist {
                albumAndArtistName?.text = artistName
            } else if let albumName = mediaItem?.albumTitle {
                albumAndArtistName?.text = albumName
            } else {
                albumAndArtistName?.text = nil
            }

            guard let identifier = mediaItem?.playbackStoreID, let imagePointSize = self.albumArt?.bounds.size,
                let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                albumArt?.image = nil
                return
            }

            // Convert the point size to pixel size for the artwork image.
            let scaleFactor = UIScreen.main.scale
            let imagePixelSize = CGSize(width: imagePointSize.width * scaleFactor, height: imagePointSize.height * scaleFactor)

            appDelegate.fetchUIImageForIdentifier(identifier, ofSize: imagePixelSize, completion: { image in
                DispatchQueue.main.async {
                    self.albumArt?.image = image
                }
            })
        }
    }

    @IBAction private func playPause(sender: UIButton) {
        let player = MPMusicPlayerController.systemMusicPlayer

        if player.playbackState == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    @IBAction private func skipBackwards(sender: UIButton) {
        MPMusicPlayerController.systemMusicPlayer.skipToPreviousItem()
    }

    @IBAction private func skipForwards(sender: UIButton) {
        MPMusicPlayerController.systemMusicPlayer.skipToNextItem()
    }
}

