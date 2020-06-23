/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The implementation of a utility class that facilitates frame captures from the device
 camera.
*/

import AVFoundation
import CoreVideo
import UIKit
import VideoToolbox

protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame image: CGImage?)
}

/// - Tag: VideoCapture
class VideoCapture: NSObject {
    enum VideoCaptureError: Error {
        case captureSessionIsMissing
        case invalidInput
        case invalidOutput
        case unknown
    }

    /// The delegate to receive the captured frames.
    weak var delegate: VideoCaptureDelegate?

    /// A capture session used to coordinate the flow of data from input devices to capture outputs.
    let captureSession = AVCaptureSession()

    /// A capture output that records video and provides access to video frames. Captured frames are passed to the
    /// delegate via the `captureOutput()` method.
    let videoOutput = AVCaptureVideoDataOutput()

    /// The current camera's position.
    private(set) var cameraPostion = AVCaptureDevice.Position.back

    /// The dispatch queue responsible for processing camera set up and frame capture.
    private let sessionQueue = DispatchQueue(
        label: "com.example.apple-samplecode.estimating-human-pose-with-posenet.sessionqueue")

    /// Toggles between the front and back camera.
    public func flipCamera(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                self.cameraPostion = self.cameraPostion == .back ? .front : .back

                // Indicate the start of a set of configuration changes to the capture session.
                self.captureSession.beginConfiguration()

                try self.setCaptureSessionInput()
                try self.setCaptureSessionOutput()

                // Commit configuration changes.
                self.captureSession.commitConfiguration()

                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    /// Asynchronously sets up the capture session.
    ///
    /// - parameters:
    ///     - completion: Handler called once the camera is set up (or fails).
    public func setUpAVCapture(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                try self.setUpAVCapture()
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    private func setUpAVCapture() throws {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }

        captureSession.beginConfiguration()

        captureSession.sessionPreset = .vga640x480

        try setCaptureSessionInput()

        try setCaptureSessionOutput()

        captureSession.commitConfiguration()
    }

    private func setCaptureSessionInput() throws {
        // Use the default capture device to obtain access to the physical device
        // and associated properties.
        guard let captureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: AVMediaType.video,
            position: cameraPostion) else {
                throw VideoCaptureError.invalidInput
        }

        // Remove any existing inputs.
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }

        // Create an instance of AVCaptureDeviceInput to capture the data from
        // the capture device.
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            throw VideoCaptureError.invalidInput
        }

        guard captureSession.canAddInput(videoInput) else {
            throw VideoCaptureError.invalidInput
        }

        captureSession.addInput(videoInput)
    }

    private func setCaptureSessionOutput() throws {
        // Remove any previous outputs.
        captureSession.outputs.forEach { output in
            captureSession.removeOutput(output)
        }

        // Set the pixel type.
        let settings: [String: Any] = [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]

        videoOutput.videoSettings = settings

        // Discard newer frames that arrive while the dispatch queue is already busy with
        // an older frame.
        videoOutput.alwaysDiscardsLateVideoFrames = true

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        guard captureSession.canAddOutput(videoOutput) else {
            throw VideoCaptureError.invalidOutput
        }

        captureSession.addOutput(videoOutput)

        // Update the video orientation
        if let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported {
            connection.videoOrientation =
                AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation)
            connection.isVideoMirrored = cameraPostion == .front

            // Inverse the landscape orientation to force the image in the upward
            // orientation.
            if connection.videoOrientation == .landscapeLeft {
                connection.videoOrientation = .landscapeRight
            } else if connection.videoOrientation == .landscapeRight {
                connection.videoOrientation = .landscapeLeft
            }
        }
    }

    /// Begin capturing frames.
    ///
    /// - Note: This is performed off the main thread as starting a capture session can be time-consuming.
    ///
    /// - parameters:
    ///     - completionHandler: Handler called once the session has started running.
    public func startCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                // Invoke the startRunning method of the captureSession to start the
                // flow of data from the inputs to the outputs.
                self.captureSession.startRunning()
            }

            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }

    /// End capturing frames
    ///
    /// - Note: This is performed off the main thread, as stopping a capture session can be time-consuming.
    ///
    /// - parameters:
    ///     - completionHandler: Handler called once the session has stopping running.
    public func stopCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let delegate = delegate else { return }

        if let pixelBuffer = sampleBuffer.imageBuffer {
            // Attempt to lock the image buffer to gain access to its memory.
            guard CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess
                else {
                    return
            }

            // Create Core Graphics image placeholder.
            var image: CGImage?

            // Create a Core Graphics bitmap image from the pixel buffer.
            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)

            // Release the image buffer.
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

            DispatchQueue.main.sync {
                delegate.videoCapture(self, didCaptureFrame: image)
            }
        }
    }
}
