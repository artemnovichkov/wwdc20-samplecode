/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utilities for loading and validating tracks from source movie.
*/

import AVFoundation
import Combine

struct SourceMedia {
	let asset: AVAsset
	let audioTrack: AVAssetTrack
	let videoTrack: AVAssetTrack
	let videoTimeScale: CMTimeScale
}

// This function loads the first audio and video track from the input file.
func loadTracks(using config: FMP4WriterConfiguration, completion: @escaping (Result<SourceMedia, Error>) -> Void) {
	let fullPath = NSString(string: config.assetPath).expandingTildeInPath
	let assetURL = URL(fileURLWithPath: fullPath)
	let asset = AVAsset(url: assetURL)
	let tracksKey = "tracks"
	
	asset.loadValuesAsynchronously(forKeys: [tracksKey]) {
		var error: NSError? = nil
		guard asset.statusOfValue(forKey: tracksKey, error: &error) == .loaded else {
			completion(.failure(error!))
			return
		}
		// For simplicity, this sample code requires that the source movie file have at least one audio and video track.
		guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
			completion(.failure(FMP4WriterError.sourceFileHasNoAudioTrack))
			return
		}
		guard let videoTrack = asset.tracks(withMediaType: .video).first else {
			completion(.failure(FMP4WriterError.sourceFileHasNoVideoTrack))
			return
		}
		
		// Load and validate the video frame rate.
		let minFrameDurationKey = "minFrameDuration"
		let naturalTimeScaleKey = "naturalTimeScale"
		videoTrack.loadValuesAsynchronously(forKeys: [minFrameDurationKey, naturalTimeScaleKey]) {
			var error: NSError? = nil
			guard videoTrack.statusOfValue(forKey: minFrameDurationKey, error: &error) == .loaded else {
				completion(.failure(error!))
				return
			}
			guard videoTrack.statusOfValue(forKey: naturalTimeScaleKey, error: &error) == .loaded else {
				completion(.failure(error!))
				return
			}
			/*
				See https://developer.apple.com/documentation/http_live_streaming/hls_authoring_specification_for_apple_devices for
				detailed guidelines on audio & video formats for HLS.
			*/
			guard videoTrack.minFrameDuration >= config.minimumAllowableSourceFrameDuration else {
				completion(.failure(FMP4WriterError.sourceFileFrameRateTooHigh))
				return
			}
			
			completion(.success(SourceMedia(asset: asset, audioTrack: audioTrack, videoTrack: videoTrack, videoTimeScale: videoTrack.naturalTimeScale)))
		}
	}
}
