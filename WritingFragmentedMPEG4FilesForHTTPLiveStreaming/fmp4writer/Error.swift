/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Error constants and descriptions
*/

import Foundation

enum FMP4WriterError: Error {
	case sourceFileHasNoAudioTrack
	case sourceFileHasNoVideoTrack
	case trackHasNoFormatDescription
	case sourceFileFrameRateTooHigh
}

extension FMP4WriterError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .sourceFileHasNoAudioTrack:
			return "Source file has no audio track"
		case .sourceFileHasNoVideoTrack:
			return "Source file has no video track"
		case .trackHasNoFormatDescription:
			return "Source track has no format description"
		case .sourceFileFrameRateTooHigh:
			return "Source file's video frame rate is too high"
		}
	}
}
