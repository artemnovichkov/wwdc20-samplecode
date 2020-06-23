/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main workflow for converting an input movie file to a directory of segment files.
*/

import AVFoundation
import Combine

// Parse the input arguments.
guard CommandLine.arguments.count == 3 else {
	let commandPath = CommandLine.arguments[0]
	let commandName = URL(fileURLWithPath: commandPath).lastPathComponent
	print("Usage: \(commandName) <movie file> <output directory> ")
	exit(1)
}
let config = FMP4WriterConfiguration(assetPath: CommandLine.arguments[1], outputDirectoryPath: CommandLine.arguments[2])

// This is the result of the asynchronous operations.
var result: Subscribers.Completion<Error>?

// These are needed to keep the asynchronous operations running.
var segmentGenerationToken: Any?
var segmentAndIndexFileWriter: AnyCancellable?

let group = DispatchGroup()
group.enter()

// Asynchronously load tracks from the source movie file.
loadTracks(using: config) { trackLoadingResult in
	do {
		let sourceMedia = try trackLoadingResult.get()
		
		// Make sure that the output directory exists.
		let fullOutputPath = NSString(string: config.outputDirectoryPath).expandingTildeInPath
		let outputDirectoryURL = URL(fileURLWithPath: fullOutputPath, isDirectory: true)
		try FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
		print("Writing segment files to directory \(outputDirectoryURL)")
		
		// Set up the processing pipelines.
		
		// Generate a stream of Segment structures.
		// This will be hooked up to the segment generation code after the processing chains have been set up.
		let segmentGenerator = PassthroughSubject<Segment, Error>()
		
		// Generate an index file from a stream of Segments.
		let indexFileGenerator = segmentGenerator.reduceToIndexFile(using: config)
		
		// Write each segment to disk.
		let segmentFileWriter = segmentGenerator
			.tryMap { segment in
				let segmentFileName = segment.fileName(forPrefix: config.segmentFileNamePrefix)
				let segmentFileURL = URL(fileURLWithPath: segmentFileName, isDirectory: false, relativeTo: outputDirectoryURL)

				print("writing \(segment.data.count) bytes to \(segmentFileName)")
				try segment.data.write(to: segmentFileURL)
			}
		
		// Write the index file to disk.
		let indexFileWriter = indexFileGenerator
			.tryMap { finalIndexFile in
				let indexFileURL = URL(fileURLWithPath: config.indexFileName, isDirectory: false, relativeTo: outputDirectoryURL)
				
				print("writing index file to \(config.indexFileName)")
				try finalIndexFile.write(to: indexFileURL, atomically: false, encoding: .utf8)
			}
		
		// Collect the results of segment and index file writing.
		segmentAndIndexFileWriter = segmentFileWriter.merge(with: indexFileWriter)
			.sink(receiveCompletion: { completion in
				result = completion
				group.leave()
			}, receiveValue: {})
		
		// Now that all the processing pipelines are set up, start the flow of data and wait for completion.
		segmentGenerationToken = generateSegments(sourceMedia: sourceMedia, configuration: config, subject: segmentGenerator)
	} catch {
		result = .failure(error)
		group.leave()
	}
}

// Wait for the asynchronous processing to finish.
group.wait()

// Evaluate the result.
switch result! {
case .finished:
	assert(segmentGenerationToken != nil)
	assert(segmentAndIndexFileWriter != nil)
	print("Finished writing segment data")
case .failure(let error):
	switch error {
	case let localizedError as LocalizedError:
		print("Error: \(localizedError.errorDescription ?? String(describing: localizedError))")
	default:
		print("Error: \(error)")
	}
	exit(1)
}
