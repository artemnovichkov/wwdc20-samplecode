/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class builds an AVVideoComposition object by applying a custom CIFilter to the source asset.
 The filter highlights pixels in the extended dynamic range by painting them with rolling stripes.
*/

import Foundation
import AVKit
import AVFoundation
import CoreImage

class AVVideoCompositionBuilder {
    static func buildVideoComposition(asset: AVAsset, avComposition: AVComposition) -> AVVideoComposition {
        
        let context = CIContext(options: [.cacheIntermediates: false, .name: "videoComp"])
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        return AVMutableVideoComposition(asset: asset) { request in
            let source = request.sourceImage
            let time = Float((request.compositionTime - timeRange.start).seconds)
            let ciFilter = HDRIndicatorFilter()
            ciFilter.inputImage = source
            ciFilter.inputTime = time
            
            if let output = ciFilter.outputImage {
                request.finish(with: output, context: context)
            } else {
                request.finish(with: FilterError.failedToProduceOutputImage)
            }
        }
    }
}
