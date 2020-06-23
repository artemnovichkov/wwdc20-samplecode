/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This is a custom container view controller that is responsible for two things:
    1. Hosting the CameraViewController that presents video frames captured by camera or being read from video file
    2. Presentation and dismissal of overlay view controllers based on current game state
*/

import UIKit

class RootViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    
    private var cameraViewController: CameraViewController!
    private var overlayParentView: UIView!
    private var overlayViewController: UIViewController!
    private let gameManager = GameManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraViewController = CameraViewController()
        cameraViewController.view.frame = view.bounds
        addChild(cameraViewController)
        cameraViewController.beginAppearanceTransition(true, animated: true)
        view.addSubview(cameraViewController.view)
        cameraViewController.endAppearanceTransition()
        cameraViewController.didMove(toParent: self)
        overlayParentView = UIView(frame: view.bounds)
        overlayParentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayParentView)
        NSLayoutConstraint.activate([
            overlayParentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            overlayParentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            overlayParentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            overlayParentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        startObservingStateChanges()
        // Make sure close button stays in front of other views.
        view.bringSubviewToFront(closeButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameManager.stateMachine.enter(GameManager.SetupCameraState.self)
    }
    
    private func presentOverlayViewController(_ newOverlayViewController: UIViewController?, completion: (() -> Void)?) {
        defer {
            completion?()
        }
        
        guard overlayViewController != newOverlayViewController else {
            return
        }
        
        if let currentOverlay = overlayViewController {
            currentOverlay.willMove(toParent: nil)
            currentOverlay.beginAppearanceTransition(false, animated: true)
            currentOverlay.view.removeFromSuperview()
            currentOverlay.endAppearanceTransition()
            currentOverlay.removeFromParent()
        }
        
        if let newOverlay = newOverlayViewController {
            newOverlay.view.frame = overlayParentView.bounds
            addChild(newOverlay)
            newOverlay.beginAppearanceTransition(true, animated: true)
            overlayParentView.addSubview(newOverlay.view)
            newOverlay.endAppearanceTransition()
            newOverlay.didMove(toParent: self)
        }
        
        overlayViewController = newOverlayViewController
    }
}

// MARK: - Handle states that require view controller transitions

// This is where the overlay controllers management happens.
extension RootViewController: GameStateChangeObserver {
    func gameManagerDidEnter(state: GameManager.State, from previousState: GameManager.State?) {
        // Create an overlay view controller based on the game state
        let controllerToPresent: UIViewController
        switch state {
        case is GameManager.DetectingBoardState:
            controllerToPresent = SetupViewController()
        case is GameManager.DetectingPlayerState:
            controllerToPresent = GameViewController()
        case is GameManager.ShowSummaryState:
            controllerToPresent = SummaryViewController()
        default:
            //The new state does not require new view controller, so just return.
            return
        }
        
        // Remove existing overlay controller (if any) from game manager listeners
        if let currentListener = overlayViewController as? GameStateChangeObserverViewController {
            currentListener.stopObservingStateChanges()
        }
        
        presentOverlayViewController(controllerToPresent) {
            //Adjust safe area insets on overlay controller to match actual video outpput area.
            if let cameraVC = self.cameraViewController {
                let viewRect = cameraVC.view.frame
                let videoRect = cameraVC.viewRectForVisionRect(CGRect(x: 0, y: 0, width: 1, height: 1))
                let insets = controllerToPresent.view.safeAreaInsets
                let additionalInsets = UIEdgeInsets(
                        top: videoRect.minY - viewRect.minY - insets.top,
                        left: videoRect.minX - viewRect.minX - insets.left,
                        bottom: viewRect.maxY - videoRect.maxY - insets.bottom,
                        right: viewRect.maxX - videoRect.maxX - insets.right)
                controllerToPresent.additionalSafeAreaInsets = additionalInsets
            }

            // If new overlay controller conforms to GameManagerListener, add it to the listeners.
            if let gameManagerListener = controllerToPresent as? GameStateChangeObserverViewController {
                gameManagerListener.startObservingStateChanges()
            }
            
            // If new overlay controller conforms to CameraViewControllerOutputDelegate
            // set it as a CameraViewController's delegate, so it can process the frames
            // that are coming from the live camera preview or being read from pre-recorded video file.
            if let outputDelegate = controllerToPresent as? CameraViewControllerOutputDelegate {
                self.cameraViewController.outputDelegate = outputDelegate
            }
        }
    }
}
