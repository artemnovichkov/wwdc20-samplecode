/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Audio Component
*/

import Foundation
import RealityKit
import Combine

public struct AudioComponent: Component {
    fileprivate var audioResources = [String: AudioFileResource]()
}

public protocol HasAudioComponent where Self: Entity {}

extension HasAudioComponent where Self: Entity {
    public var audioComponent: AudioComponent {
        get { return components[AudioComponent.self] ?? AudioComponent() }
        set { components[AudioComponent.self] = newValue }
    }

    public func addSound(_ audioFile: AudioFileResource?, name: String) {
        guard let audioFile = audioFile else { return }
        audioComponent.audioResources[name] = audioFile
    }

    public func playSound(name: String) {
        stopAllAudio()
        guard let sound = audioComponent.audioResources[name] else { return }
        playAudio(sound)
    }
}
