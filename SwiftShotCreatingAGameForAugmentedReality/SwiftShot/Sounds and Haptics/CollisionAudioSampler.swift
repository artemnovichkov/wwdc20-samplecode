/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Modulates audio SFX for ball/block/table collisions based on physics parameters.
*/

import UIKit
import AVFoundation
import SceneKit
import simd

class CollisionAudioSampler: AudioSampler {
    struct Note {
        static let collisionWithBall: UInt8 = 60 // Midi note for C4
        static let collisionWithBlock: UInt8 = 52 // Midi note for E3
        static let collisionWithTable: UInt8 = 55 // Midi note for G3
    }

    /// This is a record of the Midi Note and Velocity sent to the audio sampler on this
    /// GameAudioComponent. This is synchronized to other devices sharing the game and
    /// will be played on the corresponding objects on those devices too.
    struct CollisionEvent {
        let note: UInt8
        let velocity: UInt8
        let modWheel: Float // only requires 7-bit accuracy in range 0..1
    }

    struct Config: Codable {
        let minimumImpulse: CGFloat
        let maximumImpulse: CGFloat
        let velocityMinimum: CGFloat
        let velocityMaximum: CGFloat
        let presetName: String

        static func create(from properties: [String: Any]) -> Config? {
            if let minimumImpulse = properties["minimumImpulse"] as? CGFloat,
                let maximumImpulse = properties["maximumImpulse"] as? CGFloat,
                let velocityMinimum = properties["velocityMinimum"] as? CGFloat,
                let velocityMaximum = properties["velocityMaximum"] as? CGFloat,
                let presetName = properties["presetName"] as? String {
                return Config(minimumImpulse: minimumImpulse,
                              maximumImpulse: maximumImpulse,
                              velocityMinimum: velocityMinimum,
                              velocityMaximum: velocityMaximum,
                              presetName: presetName)
            } else {
                return nil
            }
        }
    }

    let config: Config

    // Each time a note is played, choose a variant of +/- a bit of the midi note.
    // The sampler cannot play two of the same note at the same time (which makes
    // sense for music instruments like pianos, but we may want to hear two ball
    // bounce sounds, so they need to be different midi notes.)
    var variant = [-1, 0, 1, 2]

    init(node: SCNNode, config: Config, sfxCoordinator: SFXCoordinator) {
        self.config = config
        super.init(name: config.presetName, node: node, sfxCoordinator: sfxCoordinator)
    }

    func createCollisionEvent(impulse: CGFloat, withBall: Bool, withTable: Bool) -> CollisionEvent? {
        if impulse.isNaN || impulse < config.minimumImpulse {
            return nil
        }

        // Set mod wheel according to the impulse value. This will vary the attack of the sound
        // and make them less repetitive and more dynamic. The sampler patch is set up to play the full
        // sound with modWheel off, and shortened attack with increasing modwheel value. So we invert the
        // normalized range.
        //
        // Also, we want to alter the velocity so that higher impulse means a louder note.

        var note: UInt8
        if withTable {
            note = Note.collisionWithTable
        } else if withBall {
            note = Note.collisionWithBall
        } else {
            note = Note.collisionWithBlock
        }

        note = UInt8(Int(note) + variant[0])

        // move this variant randomly to another position
        let otherIndex = Int(arc4random_uniform(UInt32(variant.count - 1)))
        variant.swapAt(0, 1 + otherIndex)

        var normalizedImpulse = clamp((impulse - config.minimumImpulse) / (config.maximumImpulse - config.minimumImpulse), 0.0, 1.0)

        // Once the impulse is normalized to the range 0...1, doing a sqrt
        // on it causes lower values to be higher. This curve was chosen because
        // it sounded better aesthetically.
        normalizedImpulse = sqrt(normalizedImpulse)

        let rangedImpulse = config.velocityMinimum + (config.velocityMaximum - config.velocityMinimum) * normalizedImpulse
        let velocity = UInt8(clamp(rangedImpulse, 0, 127))

        return CollisionEvent(note: note, velocity: velocity, modWheel: Float(1.0 - normalizedImpulse))
    }

    func play(collisionEvent: CollisionEvent) {
        modWheel = collisionEvent.modWheel
        play(note: collisionEvent.note, velocity: collisionEvent.velocity)
    }
}
