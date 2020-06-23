/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view controller.
*/

import UIKit

extension Orientation {
    init(_ interfaceOrientation: UIInterfaceOrientation) {
        self.init(rawValue: interfaceOrientation.rawValue)!
    }
}
class MainViewController: UIViewController {
    
    private let controller = AudioController()
    private let recordingOptions = AudioController.recordingOptions
    private var windowOrientation: UIInterfaceOrientation { view.window?.windowScene?.interfaceOrientation ?? .unknown }
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var levelMeter: StereoLevelMeterView!
    @IBOutlet weak var layoutView: StereoLayoutView!
    @IBOutlet weak var recordingOptionChooser: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        levelMeter.levelProvider = controller
        recordingOptionChooser.removeAllSegments()
        for (i, option) in recordingOptions.enumerated() {
            recordingOptionChooser.insertSegment(withTitle: option.name, at: i, animated: false)
        }
        recordingOptionChooser.selectedSegmentIndex = 0
        controller.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !controller.isDeviceSupported {
            playButton.isEnabled = false
            recordButton.isEnabled = false
            recordingOptionChooser.isEnabled = false
            showAlert(title: "Unsupported Device", message: "Your device doesn't support this sample.")
        } else {
            selectRecordingOption()
        }
    }
    
    @IBAction func record(_ sender: UIButton) {
        // Disable the play button until the recording completes.
        
        if !sender.isSelected {
            levelMeter.start()
            controller.record()
            playButton.isEnabled = false
            shareButton.isEnabled = false
            recordingOptionChooser.isEnabled = false
        } else {
            controller.stopRecording()
            levelMeter.stop()
            playButton.isEnabled = true
            shareButton.isEnabled = true
            recordingOptionChooser.isEnabled = true
        }
        
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func play(_ sender: UIButton) {
        // Disable the play button until the recording completes.
        if !sender.isSelected {
            controller.play()
            recordButton.isEnabled = false
            levelMeter.start()
        } else {
            controller.stopPlayback()
            recordButton.isEnabled = true
            levelMeter.stop()
        }
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func shareRecording(_ sender: UIButton) {
        guard let url = controller.recordingURL else { return }
        let viewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(viewController, animated: true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        selectRecordingOption()
    }
    
    @IBAction func updateRecordingOption(_ sender: Any) {
        selectRecordingOption()
    }
    
    private func selectRecordingOption() {
        // Don't update the data source if the app is currently recording.
        guard controller.state != .recording else { return }
        let option = recordingOptions[recordingOptionChooser.selectedSegmentIndex]
        controller.selectRecordingOption(option, orientation: Orientation(windowOrientation)) { layout in
            self.layoutView.layout = layout
        }
    }
    
    // MARK: - Notifications
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            self.dismiss(animated: false)
        })
        present(alert, animated: true)
    }
}

extension MainViewController: AudioControllerDelegate {
    
    func audioControllerDidStopPlaying() {
        playButton.isSelected = false
        recordButton.isEnabled = true
        shareButton.isEnabled = true
    }
}

