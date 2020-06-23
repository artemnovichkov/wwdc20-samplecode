/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Handles destruction of slingshots when hit by other team's shots.
*/

import Foundation
import GameplayKit
import os.log

class PlayerTriggerComponent: GKComponent, CollisionHandlerComponent {
    let catapult: SCNNode
    
    init(catapult: SCNNode) {
        self.catapult = catapult
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // if the catapult id does not match the catapult that shot the cannon,
    // spawn a broken version of the slingshot
    func didCollision(manager: GameManager, node: SCNNode, otherNode: SCNNode, pos: SIMD3<Float>, impulse: CGFloat) {
        // `node` should be the collisionTrigger, `otherNode` the object that went in it

        if let sourceIndex = otherNode.value(forKey: "Source") as? Int,
           let catIndex = catapult.value(forKey: "id") as? Int,
           sourceIndex != catIndex { // don't allow to shoot self
            if let physicsNode = otherNode.findNodeWithPhysicsBody(), let physicsBody = physicsNode.physicsBody {
                let vel = physicsBody.simdVelocity
                os_log(.debug, "hit vel: %f %f %f", vel.x, vel.y, vel.z)
                let hitInfo = HitCatapult(catapultID: catIndex, justKnockedout: true, vortex: false)
                manager.queueAction(gameAction: .catapultKnockOut(hitInfo)) // tell myself
                manager.send(gameAction: .catapultKnockOut(hitInfo)) // tell everyone else
            }
        }
    }
}
