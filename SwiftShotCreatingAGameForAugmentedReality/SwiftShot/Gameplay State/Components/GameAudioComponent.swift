/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Component for game objects that play audio.
*/

import Foundation
import GameplayKit
import AVFoundation

protocol GameAudioComponentDelegate: class {
    func gameAudioComponent(_ component: GameAudioComponent, didPlayCollisionEvent collisionEvent: CollisionAudioSampler.CollisionEvent)
}

class GameAudioComponent: GKComponent, CollisionHandlerComponent, TouchableComponent {
    var lastSoundTime: TimeInterval = 0  // don't play if this is not zero
    let node: SCNNode
    var hasCollisionSounds = false
    var audioSampler: CollisionAudioSampler?
    let config: CollisionAudioSampler.Config?

    var lastCollisionTime: CFAbsoluteTime = 0
    var collisionCooldown: TimeInterval = 0.5
    weak var delegate: GameAudioComponentDelegate?

    var sfxCoordinator: SFXCoordinator? {
        didSet {
            if let sfxCoordinator = sfxCoordinator, hasCollisionSounds, let config = config {
                audioSampler = CollisionAudioSampler(node: node, config: config, sfxCoordinator: sfxCoordinator)
            }
        }
    }

    init(node: SCNNode, properties: [String: Any]) {
        self.node = node

        config = CollisionAudioSampler.Config.create(from: properties)

        super.init()

        if let collision = properties["collision"] as? Bool {
            hasCollisionSounds = collision
        }
    }
    
    // this is what is called if custom collision response is active
    func didCollision(manager: GameManager, node: SCNNode, otherNode: SCNNode, pos: SIMD3<Float>, impulse: CGFloat) {

        // we don't play sound if this is a triggerVolume
        if let name = node.name, name.starts(with: "CollisionTrigger") {
            return
        }
        if let name = otherNode.name, name.starts(with: "CollisionTrigger") {
            return
        }

        let names = [node.name, otherNode.name]
        let withBall = names.contains("ball")
        let withTable = names.contains("OcclusionBox")

        if node.name == "OcclusionBox" {
            // don't play any sounds on the table.
            return
        }

        var effectiveImpulse = impulse
        if withTable {
            // the table does not move, so the calculated impulse is zero (sometimes?).
            // Ensure that the ball has an impulse value, so if it happens to be zero,
            // fake one based on its velocity
            if impulse == 0 && withBall {
                if let physicsBody = node.physicsBody {
                    let v = physicsBody.velocity
                    let factor: Float = 1.5
                    let velocity = length(SIMD3<Float>(v.x, v.y, v.z))
                    effectiveImpulse = CGFloat(factor * velocity)
                } else {
                    effectiveImpulse = 0
                }
            }
        }

        prepareCollisionSound(impulse: effectiveImpulse, withBall: withBall, withTable: withTable)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // when this object collides with something else. (runs only on the server)
    func prepareCollisionSound(impulse: CGFloat, withBall: Bool, withTable: Bool) {

        if let audioSampler = audioSampler {
            let now = CFAbsoluteTimeGetCurrent()
            var collisionEvent: CollisionAudioSampler.CollisionEvent?

            if withBall {
                // always play a collision sound with the ball
                collisionEvent = audioSampler.createCollisionEvent(impulse: impulse, withBall: true, withTable: withTable)
                lastCollisionTime = now
            } else {
                // check cooldown-time.
                if lastCollisionTime == 0 || now - lastCollisionTime > collisionCooldown {
                    lastCollisionTime = now
                    collisionEvent = audioSampler.createCollisionEvent(impulse: impulse, withBall: false, withTable: withTable)
                }
            }

            if let collisionEvent = collisionEvent {
                delegate?.gameAudioComponent(self, didPlayCollisionEvent: collisionEvent)
            }
        }
    }

    // Play the collision event on the sampler. (Server and client)
    func playCollisionSound(_ collisionEvent: CollisionAudioSampler.CollisionEvent) {
        if let audioSampler = audioSampler {
            audioSampler.play(collisionEvent: collisionEvent)
        }
    }
}
