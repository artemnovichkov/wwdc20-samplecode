/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility classes. AssetLoader loads the test asset with compositions. AssetExporter exports the edited test asset to a .mov file.
*/

import Foundation
import AVKit
import AVFoundation
import CoreImage

class AssetLoader {
    static func loadAsCompositions() -> (AVComposition, AVVideoComposition) {
        guard let url = Bundle.main.url(forResource: "HDRMovie", withExtension: "mov") else {
            fatalError("The required video asset wasn't found in the app bundle.")
        }
        
        let asset = AVAsset(url: url)
        
        let avComposition = AVMutableComposition()
        
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        let videoTrack = avComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        if let sourceTrack = asset.tracks(withMediaType: .video).first {
            try? videoTrack?.insertTimeRange(timeRange, of: sourceTrack, at: .zero)
        }
        
        let videoComposition = AVVideoCompositionBuilder.buildVideoComposition(asset: asset, avComposition: avComposition)
        
        return (avComposition, videoComposition)
    }
}

class AssetExporter {
    struct ProgressChecker {
        private var exportSession: AVAssetExportSession? = nil
        var progress: Float { exportSession?.progress ?? 0 }
        var succeeded: Bool { exportSession?.status == .completed }
        var inProgress: Bool { exportSession?.status == .exporting }
        
        init (exportSession: AVAssetExportSession?) {
            self.exportSession = exportSession
        }
    }
    static func exportAsynchronously(url: URL, completionHandler : @escaping () -> Void) -> ProgressChecker {
        let (avComposition, videoComposition) = AssetLoader.loadAsCompositions()
        guard let exportSession = AVAssetExportSession(asset: avComposition,
                                                       presetName: AVAssetExportPresetHEVCHighestQuality) else {
            fatalError("Unable to create AVAssetExportSession.")
        }
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = url
        exportSession.exportAsynchronously {
            // Invoke the completion handler if the export session is completed, failed, or cancelled.
            if [.completed, .failed, .cancelled].contains(exportSession.status) {
                completionHandler()
            }
        }
        return AssetExporter.ProgressChecker(exportSession: exportSession)
    }
}

enum FilterError: Int, Error, LocalizedError {
    case failedToProduceOutputImage = -1_000_001
    
    var errorDescription: String? {
        switch self {
        case .failedToProduceOutputImage:
            return "CIFilter does not produce an output image"
        }
    }
}

class HDRIndicatorFilter: CIFilter {
    
    var inputImage: CIImage?
    var inputTime: Float = 0.0
    
    static var kernel: CIColorKernel = {
        guard let url = Bundle.main.url(forResource: "HDRIndicator", withExtension: "ci.metallib") else {
            fatalError("Unable to find the required Metal shader.")
        }
        do {
            let data = try Data(contentsOf: url)
            return try CIColorKernel(functionName: "HDRHighlight", fromMetalLibraryData: data)
        } catch {
            fatalError("Unable to load the kernel.")
        }
    }()
    
    override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }
        return HDRIndicatorFilter.kernel.apply(extent: input.extent, arguments: [input, inputTime])
    }
}
