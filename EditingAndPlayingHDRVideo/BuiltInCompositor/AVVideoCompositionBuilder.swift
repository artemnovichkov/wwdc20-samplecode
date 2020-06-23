/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class builds an AVVideoComposition object using the built-in compositor.
 The video composition instructs the built-in compositor to flip the input
 source frames upside down.
*/

import Foundation
import AVKit
import AVFoundation

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
        let identityAffine = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
        let verticalFlipAffine = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: assetSize.height)
        var transferDuration = CMTime(value: 85, timescale: 30)
        
        if asset.duration < transferDuration {
            transferDuration = asset.duration
        }
        let transferTimeRange = CMTimeRange(start: .zero, duration: transferDuration )
        layerInstruction.setTransformRamp(fromStart: identityAffine, toEnd: verticalFlipAffine, timeRange: transferTimeRange)
        instructionLayers.append(layerInstruction)
        
        let compositionInstruction = AVMutableVideoCompositionInstruction()
        compositionInstruction.timeRange = timeRange
        compositionInstruction.layerInstructions = instructionLayers
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [compositionInstruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = assetSize
        return videoComposition
    }
}
