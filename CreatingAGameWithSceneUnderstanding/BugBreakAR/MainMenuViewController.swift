/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main Menu View Controller
*/

import Foundation
import AVFoundation
import UIKit
import RealityKit
import Combine

class MainMenuViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var accessDeniedLabel: UILabel!
    @IBOutlet weak var tapToBeginLabel: UILabel!
    @IBOutlet weak var tapGesture: UITapGestureRecognizer!

    private var assets: GameAssets?
    private var loadRequest: AnyCancellable?
    private var arView: ARView? = ARView()
    private var isPermissionDenied = true

    override var prefersStatusBarHidden: Bool { return true }

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        settingsButton.isHidden = true
        accessDeniedLabel.isHidden = true
        tapToBeginLabel.isHidden = true
        tapGesture.isEnabled = false
        activityIndicator.startAnimating()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.permissionGranted()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.permissionGranted()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.permissionDenied()
                    }
                }
            }
        default:
            permissionDenied()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            guard let destination = navController.viewControllers.first as? DebugSettingsViewController else {
                return
            }
            OptionsSettings.onSequeToDebugSettingsViewController(destination, delegate: nil)
            destination.onDismissComplete = {
                navController.dismiss(animated: true, completion: nil)
                OptionsSettings.onDebugSettingsViewControllerDismiss()
            }
        } else if let destination = segue.destination as? GameViewController {
            destination.assets = self.assets
        }
    }

    private func permissionDenied() {
        accessDeniedLabel.isHidden = false
        activityIndicator.stopAnimating()
        tapGesture.isEnabled = true
    }

    private func permissionGranted() {
        isPermissionDenied = false
        view.addSubview(arView!)
        Options.load()
        OptionsSettings.configureDebugSetting()
        loadRequest = GameAssets.loadAssetsAsync()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { assets in
                    self.assets = assets
                    self.assetsFinishedLoading()
                  })
    }

    private func assetsFinishedLoading() {
        arView?.removeFromSuperview()
        arView = nil
        activityIndicator.stopAnimating()
        settingsButton.isHidden = false
        tapToBeginLabel.isHidden = false
        tapGesture.isEnabled = true
    }

    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if isPermissionDenied {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            } else {
                performSegue(withIdentifier: "GameControllerSegue", sender: self)
            }
        }
    }
}
