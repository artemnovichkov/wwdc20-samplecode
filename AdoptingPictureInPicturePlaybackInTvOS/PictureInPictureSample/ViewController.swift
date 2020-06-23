/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller of the app that shows playback items,
        presents player view controllers, and responds to delegate methods of
        AVPlayerViewController and CustomPlayerViewController.
*/

import AVKit
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let titles = ["AVPlayerViewController", "Custom Player"]
        let buttonGridView = ButtonGridView(numberOfColumns: 2, numberOfRows: 2, delegate: self, titles: titles)

        buttonGridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonGridView)

        NSLayoutConstraint.activate([
            buttonGridView.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            buttonGridView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 200),
            buttonGridView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -200),
            buttonGridView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200)
        ])
    }

    func play(item: PlaybackItem) {
        // Create a player and player view controller based on the user's selection.
        let player = AVQueuePlayer(playerItem: item.video.playerItem)

        let playerViewController: UIViewController

        switch item.playerKind {
        case .avPlayerViewController:
            let avpvc = AVPlayerViewController()
            avpvc.player = player
            avpvc.delegate = self

            playerViewController = avpvc

        case .customPlayerViewController:
            let cpvc = CustomPlayerViewController()
            cpvc.player = player
            cpvc.delegate = self

            playerViewController = cpvc
        }

        // Present the player view controller and begin playing the video upon completion.
        present(playerViewController, animated: true) {
            player.play()
        }
    }

}

// MARK: AVPlayerViewControllerDelegate

extension ViewController: AVPlayerViewControllerDelegate {

    @objc func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
        if let presentedViewController = presentedViewController as? AVPlayerViewController,
            presentedViewController == playerViewController {
            return true
        }
        return false
    }

    @objc func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
        // Dismiss the controller when PiP starts so that the user is returned to the item selection screen.
        return true
    }

    @objc func playerViewController(_ playerViewController: AVPlayerViewController,
                                    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        restore(playerViewController: playerViewController, completionHandler: completionHandler)
    }
}

// MARK: CustomPlayerViewControllerDelegate

extension ViewController: CustomPlayerViewControllerDelegate {

    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: CustomPlayerViewController) -> Bool {
        // Dismiss the controller when PiP starts so that the user is returned to the item selection screen.
        return true
    }

    func playerViewController(_ playerViewController: CustomPlayerViewController,
                              restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        restore(playerViewController: playerViewController, completionHandler: completionHandler)
    }

}

// MARK: Common Player View Controller Delegate Handling

extension ViewController {

    func restore(playerViewController: UIViewController, completionHandler: @escaping (Bool) -> Void) {
        // Restore the player view controller when coming back from PiP (expanding to full screen).
        // If there's already a presented controller, dismiss it and then present the new one; otherwise present it immediately.
        if let presentedViewController = presentedViewController {
            presentedViewController.dismiss(animated: false) { [weak self] in
                self?.present(playerViewController, animated: false) {
                    completionHandler(true)
                }
            }
        } else {
            present(playerViewController, animated: false) {
                completionHandler(true)
            }
        }
    }
}

// MARK: ButtonGridViewDelegate

extension ViewController: ButtonGridViewDelegate {

    func buttonGrid(_ buttonGrid: ButtonGridView, titleForButtonAtIndexPath indexPath: IndexPath) -> String {
        let item = PlaybackItem(indexPath: indexPath)

        switch item.video {
        case .video1: return "Video 1"
        case .video2: return "Video 2"
        }
    }

    func buttonGrid(_ buttonGrid: ButtonGridView, didSelectItemAtIndexPath indexPath: IndexPath) {
        let item = PlaybackItem(indexPath: indexPath)

        play(item: item)
    }

}
