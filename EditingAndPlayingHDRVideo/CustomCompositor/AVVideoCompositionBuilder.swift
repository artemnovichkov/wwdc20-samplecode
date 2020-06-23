/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class builds an AVVideoComposition object that uses a custom compositor class.
 The custom compositor applies filter effect to the input source frames using a custom CIFilter.
 The filter highlights pixels in the extended dynamic range by painting them with rolling stripes
*/

import Foundation
import AVKit
import AVFoundation
import CoreImage

enum CustomCompositorError: Int, Error, LocalizedError {
    case ciFilterFailedToProduceOutputImage = -1_000_001
    case notSupportingMoreThanOneSources
    
    var errorDescription: String? {
        switch self {
        case .ciFilterFailedToProduceOutputImage:
            return "CIFilter does not produce an output image."
        case .notSupportingMoreThanOneSources:
            return "This custom compositor does not support blending of more than one source."
        }
    }
}

class SampleCustomCompositor: NSObject, AVVideoCompositing {
    private let filter = HDRIndicatorFilter()
    private let coreImageContext = CIContext(options: [CIContextOption.cacheIntermediates: false])
    
    var sourcePixelBufferAttributes: [String: Any]? = [String(kCVPixelBufferPixelFormatTypeKey): [kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange]]
    var requiredPixelBufferAttributesForRenderContext: [String: Any] =
        [String(kCVPixelBufferPixelFormatTypeKey): [kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange]]
    
    var supportsWideColorSourceFrames = true
    
    var supportsHDRSourceFrames = true
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        return
    }
    
    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        
        guard let outputPixelBuffer = request.renderContext.newPixelBuffer() else {
            print("No valid pixel buffer found. Returning.")
            request.finish(with: CustomCompositorError.ciFilterFailedToProduceOutputImage)
            return
        }
        
        guard let requiredTrackIDs = request.videoCompositionInstruction.requiredSourceTrackIDs, !requiredTrackIDs.isEmpty else {
            print("No valid track IDs found in composition instruction.")
            return
        }
        
        let sourceCount = requiredTrackIDs.count
        
        if sourceCount > 1 {
            request.finish(with: CustomCompositorError.notSupportingMoreThanOneSources)
            return
        }
        
        if sourceCount == 1 {
            let sourceID = requiredTrackIDs[0]
            let sourceBuffer = request.sourceFrame(byTrackID: sourceID.value(of: Int32.self)!)!
            let sourceCIImage = CIImage(cvPixelBuffer: sourceBuffer)
            filter.inputImage = sourceCIImage
            filter.inputTime = Float(request.compositionTime.seconds)
            if let outputImage = filter.outputImage {
                let renderDestination = CIRenderDestination(pixelBuffer: outputPixelBuffer)
                do {
                    try coreImageContext.startTask(toRender: outputImage, to: renderDestination)
                } catch {
                    print("Error starting request: \(error)")
                }
            }
        }
        
        request.finish(withComposedVideoFrame: outputPixelBuffer)
    }
}

class AVVideoCompositionBuilder {
    static func buildVideoComposition(asset: AVAsset, avComposition: AVComposition) -> AVVideoComposition {
        
        let videoTracks = avComposition.tracks(withMediaType: .video)
        
        guard !videoTracks.isEmpty, let videoTrack = videoTracks.first else {
            fatalError("The specified asset has no video tracks.")
        }
        
        let assetSize = videoTrack.naturalSize
        let timeRange = videoTrack.timeRange
        
        var instructionLayers = [AVMutableVideoCompositionLayerInstruction]()
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instructionLayers.append(layerInstruction)
        
        let compositionInstruction = AVMutableVideoCompositionInstruction()
        compositionInstruction.timeRange = timeRange
        compositionInstruction.layerInstructions = instructionLayers
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [compositionInstruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = assetSize
        videoComposition.customVideoCompositorClass = SampleCustomCompositor.self
        return videoComposition
    }
}
