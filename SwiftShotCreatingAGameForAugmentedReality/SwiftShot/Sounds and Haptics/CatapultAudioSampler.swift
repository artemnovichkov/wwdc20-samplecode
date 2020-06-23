/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Modulates slingshot SFX audio based on player interaction.
*/

import UIKit
import AVFoundation
import SceneKit
import simd

class CatapultAudioSampler: AudioSampler {

    struct Note {
        static let stretch: UInt8 = 24 // Midi note for C1
        static let launch: UInt8 = 26 // Midi note for D1
        static let launchSwish: UInt8 = 28 // Midi note for E1
        static let grabBall: UInt8 = 31 // Midi note for G1
        static let highlightOn: UInt8 = 38 // Midi note for D2
        static let highlightOff: UInt8 = 41 // Midi note for F2
        static let broken: UInt8 = 33 // Midi note for A1
    }

    let stretchMinimumExpression: Float = 75 // in Midi controller value range 0..127
    let stretchMaximumExpression: Float = 127 // in Midi controller value range 0..127
    let stretchMaximumRate: Float = 2.5

    init(node: SCNNode, sfxCoordinator: SFXCoordinator) {
        super.init(name: "catapult", node: node, sfxCoordinator: sfxCoordinator)
    }

    func startStretch() {
        audioNode.sendController(11, withValue: 127, onChannel: 0)
        play(note: Note.stretch, velocity: 105, autoStop: false)
        pitchBend = 0
    }

    func stopStretch() {
        stop(note: Note.stretch)
        pitchBend = 0
    }

    func playLaunch(velocity: GameVelocity) {
        // For the launch, we will play two sounds: a launch twang and a swish
        var len = length(velocity.vector)
        if len.isNaN {
            len = 0
        } else {
            len = clamp(len, 0, 1)
        }

        let launchVel = UInt8(len * 30 + 80)
        play(note: Note.launch, velocity: launchVel)

        let swishVel = UInt8(len * 63 + 64)
        after(0.10) {
            self.play(note: Note.launchSwish, velocity: swishVel)
        }
    }

    var stretchDistance: Float = 0 {
        didSet {
            if stretchDistance.isNaN {
                return
            }
            // apply stretch distance as pitch bend from 0...1, using pitch variation defined
            // in the AUSampler preset.
            pitchBend = clamp(stretchDistance, 0, 1)
        }
    }

    var stretchRate: Float = 0 {
        didSet {
            if stretchRate.isNaN {
                return
            }
            let normalizedStretch = stretchRate / stretchMaximumRate
            let value = UInt8(clamp(stretchMinimumExpression + normalizedStretch * (stretchMaximumExpression - stretchMinimumExpression), 0, 127))
            // midi expression, controller change# 11
            audioNode.sendController(11, withValue: value, onChannel: 0)
        }
    }

    func playHighlightOn() {
        play(note: Note.highlightOn, velocity: 90)
    }

    func playHighlightOff() {
        play(note: Note.highlightOff, velocity: 90)
    }

    func playGrabBall() {
        // reset pitch bend to 0 on grab
        pitchBend = 0
        play(note: Note.grabBall, velocity: 110)
    }

    func playBreak() {
        play(note: Note.broken, velocity: 85)
    }
}
