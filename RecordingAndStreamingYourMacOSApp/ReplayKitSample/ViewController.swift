/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view controller object.
*/

import Cocoa
import ReplayKit

class ViewController: NSViewController,
                      RPScreenRecorderDelegate,
                      RPPreviewViewControllerDelegate,
                      RPBroadcastControllerDelegate,
                      RPBroadcastActivityControllerDelegate {
    
    // IBOutlets for record, capture, broadcast buttons
    @IBOutlet var recordButton: NSButton!
    @IBOutlet var captureButton: NSButton!
    @IBOutlet var broadcastButton: NSButton!
    @IBOutlet var cameraCheckBox: NSButton!
    @IBOutlet var microphoneCheckBox: NSButton!
    
    // Internal state variables
    private var isActive = false
    private var replayPreviewViewController: NSWindow!
    private var activityController: RPBroadcastActivityController!
    private var broadcastControl: RPBroadcastController!
    private var cameraView: NSView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the recording state.
        isActive = false
        
        // Initialize the screen recorder delegate.
        RPScreenRecorder.shared().delegate = self
        
        DispatchQueue.main.async {
            // Set the buttons's enabled state.
            self.recordButton.isEnabled = RPScreenRecorder.shared().isAvailable
            self.captureButton.isEnabled = RPScreenRecorder.shared().isAvailable
            self.broadcastButton.isEnabled = RPScreenRecorder.shared().isAvailable
        }
    }
    
    // MARK: - Screen Recorder Microphone / Camera Property methods
    @IBAction func cameraButtonTapped(_ sender: NSButton) {
        if cameraCheckBox.state == .on {
            RPScreenRecorder.shared().isCameraEnabled = true
        } else {
            RPScreenRecorder.shared().isCameraEnabled = false
        }
    }
    
    @IBAction func microphoneButtonTapped(_ sender: NSButton) {
        if microphoneCheckBox.state == .on {
            RPScreenRecorder.shared().isMicrophoneEnabled = true
        } else {
            RPScreenRecorder.shared().isMicrophoneEnabled = false
        }
    }
    
    func setupCameraView() {
        DispatchQueue.main.async {
            // Validate that the camera preview view and camera is enabled.
            if (RPScreenRecorder.shared().cameraPreviewView != nil) && RPScreenRecorder.shared().isCameraEnabled {
                // Set the camera view to the camera preview view of RPScreenRecorder.
                guard let cameraView = RPScreenRecorder.shared().cameraPreviewView else {
                    print("Unable to retrieve the cameraPreviewView from RPScreenRecorder. Returning.")
                    return
                }
                // Set the frame and position to place the camera preview view.
                cameraView.frame = NSRect(x: 0, y: self.view.frame.size.height - 100, width: 100, height: 100)
                // Ensure that the view is layer backed.
                cameraView.wantsLayer = true
                // Add camera view as a subview to the main view.
                self.view.addSubview(cameraView)
                
                self.cameraView = cameraView
            }
        }
    }
    
    func tearDownCameraView() {
        DispatchQueue.main.async {
            // Remove the camera view from the main view when tearing down the camera.
            self.cameraView?.removeFromSuperview()
        }
    }
    
    // MARK: - In-App Recording
    @IBAction func recordButtonTapped(_ sender: NSButton) {
        // First, check the internal recording state.
        if isActive == false {
            // If a recording isn't currently underway, start it.
            startRecording()
        } else {
            // If we're currently active, then the button should stop the recording.
            stopRecording()
        }
    }
    
    func startRecording() {
        RPScreenRecorder.shared().startRecording { error in
            // If there is an error, print it and set button title and state.
            if error == nil {
                // We have no error and recording has started successfully. Set the recording state.
                self.setRecordingState(active: true)
                
                // Set up camera view.
                self.setupCameraView()
            } else {
                // Print the error.
                print("Error starting recording")
                
                // Set our recording state.
                self.setRecordingState(active: false)
            }
        }
    }
    
    func stopRecording() {
        RPScreenRecorder.shared().stopRecording { previewViewController, error in
            if error == nil {
                // We don't have an error and the stop recording was successful. Present the view controller
                if previewViewController != nil {
                    DispatchQueue.main.async {
                        // Set our internal preview view controller window
                        self.replayPreviewViewController = NSWindow(contentViewController: previewViewController!)
                        
                        // Set the delegate so we know when to dismiss our preview view controller
                        previewViewController?.previewControllerDelegate = self
                        
                        // Present the preview view controller form the main window as a sheet
                        NSApplication.shared.mainWindow?.beginSheet(self.replayPreviewViewController, completionHandler: nil)
                    }
                } else {
                    // We don't have a preview view controller, we should print an error
                    print("No preview view controller to present")
                }
            } else {
                // We had an error stopping the recording, we need to print an error message
                print("Error starting recording")
            }
            
            // Set recording state.
            self.setRecordingState(active: false)
            
            // Tear down camera view.
            self.tearDownCameraView()
            
        }
    }
    
    func setRecordingState(active: Bool) {
        DispatchQueue.main.async {
            if active == true {
                // Set the button title.
                self.recordButton.title = "Stop Recording"
            } else {
                // Set the button title.
                self.recordButton.title = "Start Recording"
            }
            
            // Set the internal recording state.
            self.isActive = active
            
            // Set the other buttons' isEnabled property.
            self.captureButton.isEnabled = !active
            self.broadcastButton.isEnabled = !active
        }
    }
    
    // MARK: - RPPreviewViewController Delegate
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        // This delegate method tells the app when the user is done with the
        // preview view controller sheet (when the user exits or cancels the sheet)
        // End the presentation of the preview view controller here.
        DispatchQueue.main.async {
            NSApplication.shared.mainWindow?.endSheet(self.replayPreviewViewController)
        }
    }
    
    // MARK: - In-App Capture
    @IBAction func captureButtonTapped(_ sender: NSButton) {
        // First check the internal recording state.
        if isActive == false {
            // If we're currently not active, then the button should start the capture session.
            startCapture()
        } else {
            // If we're currently active, then the button should stop the capture session.
            stopCapture()
        }
    }
    
    func startCapture() {
        RPScreenRecorder.shared().startCapture { sampleBuffer, sampleBufferType, error in
            // This handler is called everytime replaykit is ready to give you a Video, Audio or Microphone sample.
            // We want to check several things here so that we can process these sample buffers correctly.
            // First we want to check the error, if there is an error, we should print it out
            if error != nil {
                print("Error receiving sample buffer for in app capture")
            } else {
                // We don't have an error. We should now move on and check the sample buffer for its type
                switch sampleBufferType {
                case .video:
                    self.processAppVideoSample(sampleBuffer: sampleBuffer)
                case .audioApp:
                    self.processAppAudioSample(sampleBuffer: sampleBuffer)
                case .audioMic:
                    self.processAppMicSample(sampleBuffer: sampleBuffer)
                default:
                    print("Unable to process sample buffer")
                }
            }
        } completionHandler: { error in
            // This handler is called when the capture session has started. It is only called once after the capture has started.
            // Use this handler to set your started capture state and variables
            
            if error == nil {
                // No error encountered attempting to start an in app capture session. Update the capture state.
                self.setCaptureState(active: true)
                
                // Set up camera View.
                self.setupCameraView()
            } else {
                // We encountered and error while attempting to start a in app capture session. Print an error.
                print("Error starting in app capture session")
                
                // Update our capture state
                self.setCaptureState(active: false)
            }
        }
    }
    
    func processAppVideoSample(sampleBuffer: CMSampleBuffer) {
        // An app can modify the video sample buffers as needed.
        // The sample simply prints a message to the console.
        print("Received a video sample.")
    }
    
    func processAppAudioSample(sampleBuffer: CMSampleBuffer) {
        // An app can modify the audio sample buffers as needed.
        // The sample simply prints a message to the console.
        print("Received an audio sample.")
    }
    
    func processAppMicSample(sampleBuffer: CMSampleBuffer) {
        // An app can modify the microphone audio sample buffers as needed.
        // The sample simply prints a message to the console.
        print("Received a microphone audio sample.")
    }
    
    func stopCapture() {
        RPScreenRecorder.shared().stopCapture { error in
            // The handler is called when stop capture has finished.  Update the capture state.
            self.setCaptureState(active: false)
            
            // Tear down camera view.
            self.tearDownCameraView()
            
            // Check and print error if needed.
            if error != nil {
                print("Encountered and error attempting to stop in app capture")
            }
        }
    }
    
    func setCaptureState(active: Bool) {
        DispatchQueue.main.async {
            if active == true {
                // Set the button title
                self.captureButton.title = "Stop Capture"
            } else {
                // Set the button title
                self.captureButton.title = "Start Capture"
            }
            
            // Set the internal recording state
            self.isActive = active
            
            // Set the other buttons' isEnabled property
            self.recordButton.isEnabled = !active
            self.broadcastButton.isEnabled = !active
        }
    }
    
    // MARK: - In-App Broadcast
    @IBAction func broadcastButtonTapped(_ sender: NSButton) {
        // First we check our internal recording state
        if isActive == false {
            // If not active, then present the broadcast picker.
            presentBroadcastPicker()
        } else {
            // If currently active, then the button should stop the broadcast session.
            stopBroadcast()
        }
        
    }
    
    func presentBroadcastPicker() {
        // Set the origin point for the broadcast picker.
        let broadcastPickerOriginPoint = CGPoint.zero
        
        // Show the broadcast picker
        RPBroadcastActivityController.showBroadcastPicker(at: broadcastPickerOriginPoint,
                                                          from: NSApplication.shared.mainWindow,
                                                          preferredExtensionIdentifier: nil) { broadcastActivtyController, error in
            if error == nil {
                // We did not encounter an error presenting the broadcast picker
                // Save the broadcast activity controller reference
                self.activityController = broadcastActivtyController
                
                // Set the broadcast activity controller delegate so that we can get the RPBroadcastController when the user is done with the picker.
                self.activityController.delegate = self
            } else {
                // We've encountered an error attempting to present the broadcast picker, print an error
                print("Error attempting to present broadcast activity controller")
            }
        }
    }
    
    func stopBroadcast() {
        broadcastControl.finishBroadcast { error in
            // Update the broadcast state.
            self.setBroadcastState(active: false)
            
            // Tear down the camera view.
            self.tearDownCameraView()
            
            // Check and print error if needed.
            if error != nil {
                print("Error attempting to stop in app broadcast")
            }
        }
    }
    
    func setBroadcastState(active: Bool) {
        DispatchQueue.main.async {
            if active == true {
                // Set the button title.
                self.broadcastButton.title = "Stop Broadcast"
            } else {
                // Set the button title.
                self.broadcastButton.title = "Start Broadcast"
            }
            
            // Set the internal recording state
            self.isActive = active
            
            // Set the other buttons' isEnabled property
            self.recordButton.isEnabled = !active
            self.captureButton.isEnabled = !active
        }
    }
    
    // MARK: - RPBroadcastActivityController Delegate
    func broadcastActivityController(_ broadcastActivityController: RPBroadcastActivityController,
                                     didFinishWith broadcastController: RPBroadcastController?,
                                     error: Error?) {
        if error == nil {
            // Assign the private variable to the passed back broadcast controller so that we
            // may be able to control the broadcast now that it is set up.
            broadcastControl = broadcastController
            
            // Start the broadcast
            broadcastControl.startBroadcast { error in
                // Update our broadcast state
                self.setBroadcastState(active: true)
                
                // Setup camera view
                self.setupCameraView()
            }
        } else {
            // Print an error.
            print("Error with broadcast activity controller delegate call didFinish")
        }
    }
    
    // MARK: - RPScreenRecorder Delegate
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        // This delegate call is used to let the developer know when the screen recorder's availability changed.
        DispatchQueue.main.async {
            self.recordButton.isEnabled = screenRecorder.isAvailable
            self.captureButton.isEnabled = screenRecorder.isAvailable
            self.broadcastButton.isEnabled = screenRecorder.isAvailable
        }
    }
    
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        // This delegate call is used to let you know if any of the on going recording or capture has been stopped.
        // If we have a preview view controller to give back, you should present it here.
        DispatchQueue.main.async {
            // Reset the UI state.
            self.isActive = false
            self.recordButton.title = "Start Recording"
            self.captureButton.title = "Start Capture"
            self.broadcastButton.title = "Start Broadcast"
            self.recordButton.isEnabled = true
            self.captureButton.isEnabled = true
            self.broadcastButton.isEnabled = true
            
            // Tear down camera view.
            self.tearDownCameraView()
            
            // We don't have an error and the stop recording was successful. Present the view controller.
            if previewViewController != nil {
                // Set our internal preview view controller window
                self.replayPreviewViewController = NSWindow(contentViewController: previewViewController!)
                
                // Set the delegate so we know when to dismiss our preview view controller.
                previewViewController?.previewControllerDelegate = self
                
                // Present the preview view controller form the main window as a sheet.
                NSApplication.shared.mainWindow?.beginSheet(self.replayPreviewViewController, completionHandler: nil)
            } else {
                // We don't have a preview view controller, we should print an error.
                print("No preview view controller to present")
            }
        }
    }
}

