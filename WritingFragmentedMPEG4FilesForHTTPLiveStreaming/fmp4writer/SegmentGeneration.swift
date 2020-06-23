/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utilities for generating segment data using AVFoundation.
*/

import AVFoundation
import Combine

// This is a simple structure that combines the output of AVAssetWriterDelegate with an increasing segment index.
struct Segment {
	let index: Int
	let data: Data
	let isInitializationSegment: Bool
	let report: AVAssetSegmentReport?
}

// This function sends each segment to the provided Subject, then marks the Subject as completed.
// You must keep a strong reference to the returned object until the operation completes.
func generateSegments<S>(sourceMedia: SourceMedia, configuration: FMP4WriterConfiguration, subject: S) -> Any?
where S: Subject, S.Output == Segment, S.Failure == Error {
	do {
		let readerWriter = try ReaderWriter(sourceMedia: sourceMedia, configuration: configuration, subject: subject)
		readerWriter.start()
		return readerWriter
	} catch {
		subject.send(completion: .failure(error))
		return nil
	}
}

// This is a helper object that uses AVAssetReader and AVAssetWriter to generate segment data from a source AVAsset.
// Each generated segment is passed to the provided Subject, and the Subject is marked as completed when there are no more segments.
class ReaderWriter<S>: NSObject, AVAssetWriterDelegate where S: Subject, S.Output == Segment, S.Failure == Error {
	private let assetReader: AVAssetReader
	private let assetWriter: AVAssetWriter
	private let startTimeOffset: CMTime
	private let subject: S
	private let audioReaderOutput: AVAssetReaderOutput
	private let videoReaderOutput: AVAssetReaderOutput
	private let audioWriterInput: AVAssetWriterInput
	private let videoWriterInput: AVAssetWriterInput
	private let audioDone = PassthroughSubject<Void, Error>()
	private let videoDone = PassthroughSubject<Void, Error>()
	private var done: AnyCancellable?
	private var segmentIndex = 0
	
    init(sourceMedia: SourceMedia, configuration: FMP4WriterConfiguration, subject: S) throws {
		assetReader = try AVAssetReader(asset: sourceMedia.asset)
		assetWriter = AVAssetWriter(contentType: UTType(configuration.outputContentType.rawValue)!)
		self.subject = subject
		self.startTimeOffset = configuration.startTimeOffset
		
		audioReaderOutput = AVAssetReaderTrackOutput(track: sourceMedia.audioTrack, outputSettings: configuration.audioDecompressionSettings)
		videoReaderOutput = AVAssetReaderTrackOutput(track: sourceMedia.videoTrack, outputSettings: configuration.videoDecompressionSettings)
		assetReader.add(audioReaderOutput)
		assetReader.add(videoReaderOutput)
		
		audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: configuration.audioCompressionSettings)
		videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: configuration.videoCompressionSettings)
		videoWriterInput.mediaTimeScale = sourceMedia.videoTimeScale
		assetWriter.add(audioWriterInput)
		assetWriter.add(videoWriterInput)
		
		super.init()
		
		// Configure the asset writer for writing data in fragmented MPEG-4 format.
		assetWriter.outputFileTypeProfile = configuration.outputFileTypeProfile
		assetWriter.preferredOutputSegmentInterval = CMTime(seconds: Double(configuration.segmentDuration), preferredTimescale: 1)
		assetWriter.initialSegmentStartTime = configuration.startTimeOffset
		assetWriter.delegate = self

		// The audio track and video track are transfered to the writer in parallel.
		// Wait until both are finished, then finish the whole operation.
		done = audioDone.combineLatest(videoDone)
			.sink(receiveCompletion: { [weak self] completion in
				self?.finish(completion: completion)
			}, receiveValue: { _ in })
	}
	
	func start() {
		guard assetReader.startReading() else {
			subject.send(completion: .failure(assetReader.error!))
			return
		}
		guard assetWriter.startWriting() else {
			subject.send(completion: .failure(assetWriter.error!))
			return
		}

		assetWriter.startSession(atSourceTime: startTimeOffset)

		let audioQueue = DispatchQueue(label: "audio read/write")
		let videoQueue = DispatchQueue(label: "video read/write")

		// Transfer audio data from reader to writer
		audioWriterInput.requestMediaDataWhenReady(on: audioQueue) { [weak self] in
			guard let self = self else { return }
			let completion = transferSamplesUntilWriterInputPushesBack(from: self.audioReaderOutput,
																	   to: self.audioWriterInput,
																	   of: self.assetWriter,
																	   offsettingTimeStampsBy: self.startTimeOffset)
			if let completion = completion {
				self.audioWriterInput.markAsFinished()
				self.audioDone.send(completion: completion)
			}
		}

		// Transfer video data from reader to writer.
		videoWriterInput.requestMediaDataWhenReady(on: videoQueue) { [weak self] in
			guard let self = self else { return }
			let completion = transferSamplesUntilWriterInputPushesBack(from: self.videoReaderOutput,
																	   to: self.videoWriterInput,
																	   of: self.assetWriter,
																	   offsettingTimeStampsBy: self.startTimeOffset)
			if let completion = completion {
				self.videoWriterInput.markAsFinished()
				self.videoDone.send(completion: completion)
			}
		}
	}
	
    func assetWriter(_ writer: AVAssetWriter,
                     didOutputSegmentData segmentData: Data,
                     segmentType: AVAssetSegmentType,
                     segmentReport: AVAssetSegmentReport?) {
		let isInitializationSegment: Bool
		
		switch segmentType {
		case .initialization:
			isInitializationSegment = true
		case .separable:
			isInitializationSegment = false
		@unknown default:
			print("Skipping segment with unrecognized type \(segmentType)")
			return
		}
		
		let segment = Segment(index: segmentIndex, data: segmentData, isInitializationSegment: isInitializationSegment, report: segmentReport)
		subject.send(segment)
		segmentIndex += 1
	}
	
	// Call this when done transferring audio and video data.
	// Here you evaluate the final status of the AVAssetReader and AVAssetWriter, then mark the Subject as finished.
	private func finish(completion: Subscribers.Completion<Error>) {
		switch completion {
		case .failure:
			assetReader.cancelReading()
			assetWriter.cancelWriting()
			subject.send(completion: completion)
		default:
			if assetReader.status == .completed {
				assetWriter.finishWriting {
					if self.assetWriter.status == .completed {
						self.subject.send(completion: .finished)
					} else {
						assert(self.assetWriter.status == .failed)
						self.assetReader.cancelReading()
						self.subject.send(completion: .failure(self.assetWriter.error!))
					}
				}
			} else {
				assert(assetReader.status == .failed)
				assetWriter.cancelWriting()
				subject.send(completion: .failure(assetReader.error!))
			}
		}
	}
}

// This function returns nil if the function should be called again to transfer more samples, when writer input becomes ready for more samples.
func transferSamplesUntilWriterInputPushesBack(from readerOutput: AVAssetReaderOutput,
                                               to writerInput: AVAssetWriterInput,
                                               of assetWriter: AVAssetWriter,
                                               offsettingTimeStampsBy offset: CMTime) -> Subscribers.Completion<Error>? {
	do {
		while writerInput.isReadyForMoreMediaData {
			if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
				let offsetTimingSampleBuffer = try sampleBuffer.offsettingTiming(by: offset)
				guard writerInput.append(offsetTimingSampleBuffer) else {
					// There was an error appending the sample.
					throw assetWriter.error!
				}
			} else {
				// In this case, you have read all the samples from the input file.
				return .finished
			}
		}
	} catch {
		return .failure(error)
	}
	
	// At this point, you know there is more work to be done, so return nil to indicate that there is no completion yet.
	return nil
}

extension CMSampleBuffer {
	func offsettingTiming(by offset: CMTime) throws -> CMSampleBuffer {
		let newSampleTimingInfos: [CMSampleTimingInfo]
		do {
			newSampleTimingInfos = try sampleTimingInfos().map {
				var newSampleTiming = $0
				newSampleTiming.presentationTimeStamp = $0.presentationTimeStamp + offset
				if $0.decodeTimeStamp.isValid {
					newSampleTiming.decodeTimeStamp = $0.decodeTimeStamp + offset
				}
				return newSampleTiming
			}
		} catch {
			newSampleTimingInfos = []
		}
		let newSampleBuffer = try CMSampleBuffer(copying: self, withNewTiming: newSampleTimingInfos)
		try newSampleBuffer.setOutputPresentationTimeStamp(newSampleBuffer.outputPresentationTimeStamp + offset)
		return newSampleBuffer
	}
}
