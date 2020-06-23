/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Audio Files
*/

import Foundation
import RealityKit

struct AudioFile {
    var resourceName: String
    var mode: AudioResource.InputMode
    var loop: Bool
}

class AudioFiles {
    static let popAudio = AudioFile(resourceName: Constants.popAudioName, mode: .spatial, loop: false)
    static let spawnAudio = AudioFile(resourceName: Constants.spawnAudioName, mode: .spatial, loop: false)
    static let idleAudio = AudioFile(resourceName: Constants.idleAudioName, mode: .spatial, loop: true)
    static let walkAudio = AudioFile(resourceName: Constants.walkAudioName, mode: .spatial, loop: true)
    static let flutterAudio = AudioFile(resourceName: Constants.flutterAudioName, mode: .spatial, loop: true)
    static let struggleAudio = AudioFile(resourceName: Constants.struggleAudioName, mode: .spatial, loop: true)
    static let tractorBeamActivateAudio = AudioFile(resourceName: Constants.tractorBeamActivateAudioName,
                                                    mode: .nonSpatial, loop: false)
    static let tractorBeamLoopAudio = AudioFile(resourceName: Constants.tractorBeamLoopAudioName,
                                                mode: .nonSpatial, loop: true)
    static let wooshAudio = AudioFile(resourceName: Constants.wooshAudioName, mode: .nonSpatial, loop: false)
    static let creatureDestroyAudio = AudioFile(resourceName: Constants.creatureDestroyAudioName,
                                                mode: .nonSpatial, loop: false)
}
