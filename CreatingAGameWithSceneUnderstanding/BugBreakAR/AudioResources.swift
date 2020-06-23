/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Audio Resources
*/

import AVFoundation
import Combine
import RealityKit

class AudioResources {
    static func loadAudioAsync(_ file: AudioFile) -> AnyPublisher<AudioFileResource, Error> {
        if let url = Bundle.main.url(forResource: file.resourceName, withExtension: nil) {
            return AudioFileResource.loadAsync(contentsOf: url,
                                               withName: file.resourceName,
                                               inputMode: file.mode,
                                               loadingStrategy: .preload,
                                               shouldLoop: file.loop)
                .tryMap { resource in
                    return resource
                }
                .eraseToAnyPublisher()
        } else {
            fatalError("Failed to load sound \(file.resourceName)")
        }
    }
}
