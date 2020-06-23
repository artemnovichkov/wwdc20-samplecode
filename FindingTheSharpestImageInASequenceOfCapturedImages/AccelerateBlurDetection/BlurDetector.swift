/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Blur Detector Object.
*/

import AVFoundation
import Accelerate
import UIKit
import SwiftUI
import Combine

// MARK: BlurDetector
class BlurDetector: NSObject {
    let laplacian: [Float] = [-1, -1, -1,
                              -1,  8, -1,
                              -1, -1, -1]
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    weak var resultsDelegate: BlurDetectorResultsDelegate?

    var processedCount = 0

    func configure() {
        let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        let sessionQueue = DispatchQueue(label: "session queue")
        
        sessionQueue.async {
            self.configureSession(interfaceOrientation: interfaceOrientation,
                                  sessionQueue: sessionQueue)
        }
    }
    
    private func configureSession(interfaceOrientation: UIInterfaceOrientation?, sessionQueue: DispatchQueue) {
        captureSession.beginConfiguration()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.sessionPreset = .hd1280x720
        
        if
            let interfaceOrientation = interfaceOrientation,
            let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation) {
            photoOutput.connections.forEach {
                $0.videoOrientation = videoOrientation
            }
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    fatalError("App requires camera access.")
                }
                sessionQueue.resume()
                return
            })
        default:
            fatalError("App requires camera access.")
        }
        
        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .front),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                fatalError("Can't create camera.")
        }
        
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        }
        
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
    }
    
    func takePhoto() {
        let pixelFormat: FourCharCode = {
            if photoOutput.availablePhotoPixelFormatTypes
                .contains(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
                return kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            } else if photoOutput.availablePhotoPixelFormatTypes
                .contains(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
                return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            } else {
                fatalError("No available YpCbCr formats.")
            }
        }()
   
        let exposureSettings = (0 ..< photoOutput.maxBracketedCapturePhotoCount).map { _ in
            AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(
                exposureTargetBias: AVCaptureDevice.currentExposureTargetBias)
        }
        
        let photoSettings = AVCapturePhotoBracketSettings(
            rawPixelFormatType: 0,
            processedFormat: [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat],
            bracketedSettings: exposureSettings)

        processedCount = 0
        
        photoOutput.capturePhoto(with: photoSettings,
                                 delegate: self)
    }
    
    /// Creates a grayscale `CGImage` from a array of pixel values, applying specified gamma.
    ///
    /// - Parameter pixels: The array of `UInt8` values representing the image data.
    /// - Parameter width: The image width.
    /// - Parameter height: The image height.
    /// - Parameter gamma: The gamma to apply.
    /// - Parameter orientation: The orientation of of the image.
    ///
    /// - Returns: A grayscale Core Graphics image.
    static func makeImage(fromPixels pixels: inout [Pixel_8],
                          width: Int,
                          height: Int,
                          gamma: Float,
                          orientation: CGImagePropertyOrientation) -> CGImage? {
        
        let alignmentAndRowBytes = try? vImage_Buffer.preferredAlignmentAndRowBytes(
            width: width,
            height: height,
            bitsPerPixel: 8)
        
        let image: CGImage? = pixels.withUnsafeMutableBufferPointer {
            var buffer = vImage_Buffer(data: $0.baseAddress!,
                                       height: vImagePixelCount(height),
                                       width: vImagePixelCount(width),
                                       rowBytes: alignmentAndRowBytes?.rowBytes ?? width)
            
            vImagePiecewiseGamma_Planar8(&buffer,
                                         &buffer,
                                         [1, 0, 0],
                                         gamma,
                                         [1, 0],
                                         0,
                                         vImage_Flags(kvImageNoFlags))
            
            return BlurDetector.makeImage(fromPlanarBuffer: buffer,
                                          orientation: orientation)
        }
        
        return image
    }
    
    /// Creates a grayscale `CGImage` from an 8-bit planar buffer.
    ///
    /// - Parameter sourceBuffer: The vImage containing the image data.
    /// - Parameter orientation: The orientation of of the image.
    ///
    /// - Returns: A grayscale Core Graphics image.
    static func makeImage(fromPlanarBuffer sourceBuffer: vImage_Buffer,
                          orientation: CGImagePropertyOrientation) -> CGImage? {
        
        guard  let monoFormat = vImage_CGImageFormat(bitsPerComponent: 8,
                                                     bitsPerPixel: 8,
                                                     colorSpace: CGColorSpaceCreateDeviceGray(),
                                                     bitmapInfo: []) else {
                                                        return nil
        }
        
        var outputBuffer: vImage_Buffer
        var outputRotation: Int
        
        do {
            if orientation == .right || orientation == .left {
                outputBuffer = try vImage_Buffer(width: Int(sourceBuffer.height),
                                                 height: Int(sourceBuffer.width),
                                                 bitsPerPixel: 8)
                
                outputRotation = orientation == .right ?
                    kRotate90DegreesClockwise : kRotate90DegreesCounterClockwise
            } else if orientation == .up || orientation == .down {
                outputBuffer = try vImage_Buffer(width: Int(sourceBuffer.width),
                                                 height: Int(sourceBuffer.height),
                                                 bitsPerPixel: 8)
                outputRotation = orientation == .down ?
                    kRotate180DegreesClockwise : kRotate0DegreesClockwise
            } else {
                return nil
            }
        } catch {
            return nil
        }
        
        defer {
            outputBuffer.free()
        }
        
        var error = kvImageNoError
        
        withUnsafePointer(to: sourceBuffer) { src in
            error = vImageRotate90_Planar8(src,
                                           &outputBuffer,
                                           UInt8(outputRotation),
                                           0,
                                           vImage_Flags(kvImageNoFlags))
        }
        
        if error != kvImageNoError {
            return nil
        } else {
            return try? outputBuffer.createCGImage(format: monoFormat)
        }
    }
}

// MARK: BlurDetector AVCapturePhotoCaptureDelegate extension

extension BlurDetector: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        if let error = error {
            fatalError("Error capturing photo: \(error).")
        }
        
        guard let pixelBuffer = photo.pixelBuffer else {
            fatalError("Error acquiring pixel buffer.")
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer,
                                     CVPixelBufferLockFlags.readOnly)
        
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let count = width * height
        
        let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
        let lumaRowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        
        let lumaCopy = UnsafeMutableRawPointer.allocate(byteCount: count,
                                                        alignment: MemoryLayout<Pixel_8>.alignment)
        lumaCopy.copyMemory(from: lumaBaseAddress!,
                            byteCount: count)
        
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer,
                                       CVPixelBufferLockFlags.readOnly)
        
        DispatchQueue.global(qos: .utility).async {
            self.processImage(data: lumaCopy,
                              rowBytes: lumaRowBytes,
                              width: width,
                              height: height,
                              sequenceCount: photo.sequenceCount,
                              expectedCount: photo.resolvedSettings.expectedPhotoCount,
                              orientation: photo.metadata[ String(kCGImagePropertyOrientation) ] as? UInt32)
            
            lumaCopy.deallocate()
        }
    }
    
    func processImage(data: UnsafeMutableRawPointer,
                      rowBytes: Int,
                      width: Int, height: Int,
                      sequenceCount: Int,
                      expectedCount: Int,
                      orientation: UInt32? ) {
        
        var sourceBuffer = vImage_Buffer(data: data,
                                         height: vImagePixelCount(height),
                                         width: vImagePixelCount(width),
                                         rowBytes: rowBytes)
        
        var floatPixels: [Float]
        let count = width * height
        
        if sourceBuffer.rowBytes == width * MemoryLayout<Pixel_8>.stride {
            let start = sourceBuffer.data.assumingMemoryBound(to: Pixel_8.self)
            floatPixels = vDSP.integerToFloatingPoint(
                UnsafeMutableBufferPointer(start: start,
                                           count: count),
                floatingPointType: Float.self)
        } else {
            floatPixels = [Float](unsafeUninitializedCapacity: count) {
                buffer, initializedCount in
                
                var floatBuffer = vImage_Buffer(data: buffer.baseAddress,
                                                height: sourceBuffer.height,
                                                width: sourceBuffer.width,
                                                rowBytes: width * MemoryLayout<Float>.size)
                
                vImageConvert_Planar8toPlanarF(&sourceBuffer,
                                               &floatBuffer,
                                               0, 255,
                                               vImage_Flags(kvImageNoFlags))
                
                initializedCount = count
            }
        }
        
        // Convolve with Laplacian.
        vDSP.convolve(floatPixels,
                      rowCount: height,
                      columnCount: width,
                      with3x3Kernel: laplacian,
                      result: &floatPixels)
        
        // Calculate standard deviation.
        var mean = Float.nan
        var stdDev = Float.nan
        
        vDSP_normalize(floatPixels, 1,
                       nil, 1,
                       &mean, &stdDev,
                       vDSP_Length(count))
        
        // Create display version of laplacian convolution.
        let clippedPixels = vDSP.clip(floatPixels, to: 0 ... 255)
        var pixel8Pixels = vDSP.floatingPointToInteger(clippedPixels,
                                                       integerType: UInt8.self,
                                                       rounding: .towardNearestInteger)
        
        // Create display images.
        if
            let orientation = orientation,
            let imagePropertyOrientation = CGImagePropertyOrientation(rawValue: orientation),
            let laplacianImage = BlurDetector.makeImage(fromPixels: &pixel8Pixels,
                                                        width: width, height: height,
                                                        gamma: 1 / 2.2,
                                                        orientation: imagePropertyOrientation),
            let monoImage = BlurDetector.makeImage(fromPlanarBuffer: sourceBuffer,
                                                   orientation: imagePropertyOrientation) {
            let result = BlurDetectionResult(index: sequenceCount,
                                             image: monoImage,
                                             laplacianImage: laplacianImage,
                                             score: stdDev * stdDev)
            
            print("index \(sequenceCount) : score \(stdDev * stdDev)")
            
            DispatchQueue.main.async {
                self.processedCount += 1
                self.resultsDelegate?.itemProcessed(result)
                
                if self.processedCount == expectedCount {
                    self.resultsDelegate?.finishedProcessing()
                }
            }
        }
    }
}

// MARK: BlurDetectorResultModel

class BlurDetectorResultModel: ObservableObject, BlurDetectorResultsDelegate {
    
    enum Mode {
         case camera
         case processing
         case resultsTable
     }

    @Published var blurDetectionResults = [BlurDetectionResult]()
    
    @Published var mode: Mode = .camera {
        didSet {
            if mode == .processing {
                blurDetectionResults.removeAll()
            }
            showResultsTable = mode == .resultsTable
        }
    }

    @Published var showResultsTable = false
    
    func itemProcessed(_ item: BlurDetectionResult) {
        blurDetectionResults.append(item)
    }
    
    func finishedProcessing() {
        // Sort results: variance of laplacian - higher is less blurry.
        blurDetectionResults.sort {
            $0.score > $1.score
        }
        
        mode = .resultsTable
    }
}

// MARK: BlurDetectorResultsDelegate protcol

protocol BlurDetectorResultsDelegate: class {
    func itemProcessed(_ item: BlurDetectionResult)
    func finishedProcessing()
}

// MARK: BlurDetectionResult

struct BlurDetectionResult {
    let index: Int
    let image: CGImage
    let laplacianImage: CGImage
    let score: Float
}

// Extensions to simplify conversion between orientation enums.
extension UIImage.Orientation {
    init(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(_ uiInterfaceOrientation: UIInterfaceOrientation) {
        switch uiInterfaceOrientation {
        case .unknown:
            return nil
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        @unknown default:
            return nil
        }
    }
}
