/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom playback view controller implementation powered by AVPlayerLayer and AVPictureInPictureController.
*/

import AVKit
import UIKit

// The delegate tracks instances of CustomPlayerViewController that are
// currently using PiP, or are transitioning in or out of PiP.
private var activeCustomPlayerViewControllers = Set<CustomPlayerViewController>()

protocol CustomPlayerViewControllerDelegate: AnyObject {

    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: CustomPlayerViewController) -> Bool

    func playerViewController(_ playerViewController: CustomPlayerViewController,
                              restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void)
}

class CustomPlayerViewController: UIViewController {

    weak var delegate: CustomPlayerViewControllerDelegate?

    var player: AVPlayer? {
        didSet {
            playerLayer = AVPlayerLayer(player: player)
        }
    }

    private var playerLayer: AVPlayerLayer?
    private var pictureInPictureController: AVPictureInPictureController?
    private var controlsView: CustomPlayerControlsView?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Sets the appearance of the view and the player layer.
        guard let playerLayer = playerLayer else { fatalError("Missing AVPlayerLayer") }
        view.backgroundColor = .black
        view.layer.addSublayer(playerLayer)

        // Creates an AVPictureInPictureController instance to handle Picture in Picture.
        pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
        pictureInPictureController?.delegate = self

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler(recognizer:)))
        #if os(tvOS)
        tapGestureRecognizer.allowedTouchTypes = [UITouch.TouchType.indirect].map { $0.rawValue as NSNumber }
        tapGestureRecognizer.allowedPressTypes = []
        #endif

        view.addGestureRecognizer(tapGestureRecognizer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    @objc private func tapGestureHandler(recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if controlsView == nil {
                showControls()
            } else {
                hideControls()
            }
        default:
            break
        }
    }

    private func showControls() {
        // Adds custom control buttons for manipulating the video and view.
        let controlsView = CustomPlayerControlsView(player: player, pipController: pictureInPictureController)
        controlsView.delegate = self
        controlsView.translatesAutoresizingMaskIntoConstraints = false

        controlsView.alpha = 0.0

        let controlsViewHeight: CGFloat = 180.0

        view.addSubview(controlsView)
        NSLayoutConstraint.activate([
            controlsView.heightAnchor.constraint(equalToConstant: controlsViewHeight),
            controlsView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 90),
            controlsView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -90),
            controlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60)
        ])

        UIView.animate(withDuration: 0.25) {
            controlsView.alpha = 1.0
        }

        self.controlsView = controlsView

        // Set the additional bottom safe area inset to the height of the custom UI so existing PiP windows avoid it.
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: controlsViewHeight, right: 0)
    }

    private func hideControls() {
        guard let controlsView = controlsView else { return }

        UIView.animate(withDuration: 0.25) {
            controlsView.alpha = 0.0
        } completion: { complete in
            controlsView.removeFromSuperview()
            self.controlsView = nil
        }
        // Reset the safe area inset to its default value.
        additionalSafeAreaInsets = .zero
    }

}

extension CustomPlayerViewController: CustomPlayerControlsViewDelegate {

    func controlsViewDidRequestStartPictureInPicture(_ controlsView: CustomPlayerControlsView) {
        // When the user indicates they want to start PiP playback, call `startPictureInPicture()` on AVPlayerViewController.
        // If another video is playing, doing so will automatically perform a swap.
        pictureInPictureController?.startPictureInPicture()
        hideControls()
    }

    func controlsViewDidRequestStopPictureInPicture(_ controlsView: CustomPlayerControlsView) {
        pictureInPictureController?.stopPictureInPicture()
        hideControls()
    }

    func controlsViewDidRequestControlsDismissal(_ controlsView: CustomPlayerControlsView) {
        hideControls()
    }

    func controlsViewDidRequestPlayerDismissal(_ controlsView: CustomPlayerControlsView) {
        dismiss(animated: true)
    }

}

// MARK: - AVPictureInPictureDelegate

extension CustomPlayerViewController: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // When PiP is about to start, save a reference to the
        // AVPictureInPictureControllerDelegate (in this case the host controller).
        // Doing so prevents the delegate from getting released so the app can restore it to
        // full screen later.
        activeCustomPlayerViewControllers.insert(self)
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        let shouldDismiss = delegate?.playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(self) ?? false
        if shouldDismiss {
            // Once PiP starts, dismiss the view controller so that the user is returned to the item selection.
            dismiss(animated: true, completion: nil)
        }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        // Stop tracking this controller if PiP failed, because it's not in an active state.
        activeCustomPlayerViewControllers.remove(self)
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // Stop tracking this controller when PiP stops.
        activeCustomPlayerViewControllers.remove(self)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // Pass the restore callback to the delegate for handling.
        delegate?.playerViewController(self, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
    }

}
