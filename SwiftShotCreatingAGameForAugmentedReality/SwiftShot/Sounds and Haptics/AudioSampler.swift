/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Superclass for audio SFX modulated by gameplay.
*/

import UIKit
import AVFoundation
import SceneKit
import simd
import os.log

class AudioSampler {
    let node: SCNNode
    let audioNode: AUSamplerNode
    let audioPlayer: SCNAudioPlayer
    let presetUrl: URL

    // serial queue for loading the sampler presets at background priority
    static let loadingQueue = DispatchQueue(label: "AudioSampler.loading",
                                            qos: .background,
                                            attributes: [],
                                            autoreleaseFrequency: .workItem,
                                            target: nil)
    let loaded = NSConditionLock(condition: 0)

    init(name: String, node: SCNNode, sfxCoordinator: SFXCoordinator) {
        self.node = node
        self.audioNode = AUSamplerNode()
        self.audioPlayer = SCNAudioPlayer(avAudioNode: audioNode)

        guard let presetUrl = Bundle.main.url(forResource: "Sounds/\(name)", withExtension: "aupreset") else {
            fatalError("Failed to load preset.")
        }
        self.presetUrl = presetUrl

        AudioSampler.loadingQueue.async {
            self.loaded.lock(whenCondition: 0)
            do {
                try self.audioNode.loadPreset(at: presetUrl)
            } catch {
                os_log(.error, "Failed to load preset. Error = %s", "\(error)")
            }

            sfxCoordinator.attachSampler(self, to: node)

            // now this sampler is ready to play.
            self.loaded.unlock(withCondition: 1)
        }
    }

    func after(_ interval: TimeInterval = 1.0, f: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: f)
    }

    func reloadPreset() {
        do {
            try audioNode.loadPreset(at: presetUrl)
        } catch {
            os_log(.error, "Failed to load preset. Error = %s", "\(error)")
        }
    }
    
    func play(note: UInt8, velocity: UInt8, autoStop: Bool = true) {
        guard loaded.condition == 1 else {
            os_log(.error, "Cannot play because loading is not complete")
            return
        }

        audioNode.startNote(note, withVelocity: velocity, onChannel: 0)

        if autoStop {
            after {
                self.audioNode.stopNote(note, onChannel: 0)
            }
        }
    }

    func stop(note: UInt8) {
        audioNode.stopNote(note, onChannel: 0)
    }

    func stopAllNotes() {
        // Send All Notes Off control message.
        audioNode.sendController(123, withValue: 0, onChannel: 0)
    }

    var pitchBend: Float = 0 {
        didSet {
            // MIDI pitch bend is a 14-bit value from 0..16383, with zero pitch bend
            // applied at 8192.
            let intVal = UInt16(8192 + clamp(pitchBend, -1, 1) * 8191)
            audioNode.sendPitchBend(intVal, onChannel: 0)
        }
    }

    var modWheel: Float = 0 {
        didSet {
            // MIDI mod wheel is controller #1 and in range 0..127
            let intVal = UInt8(clamp(modWheel, 0, 1) * 127)
            audioNode.sendController(1, withValue: intVal, onChannel: 0)
        }
    }
}
