/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Smooths correction of physics state from network sync vs local simulation.
*/

import Foundation
import GameplayKit

class GamePhysicsSmoothComponent: GKComponent {
    let physicsNode: SCNNode
    let geometryNode: SCNNode
    let smoothStrength: Float = 0.2
    var parentOffPos: SIMD3<Float>
    var parentOffRot: simd_quatf
    var sourceOffPos = SIMD3<Float>(repeating: 0.0)
    var sourceOffRot = simd_quatf()
    let maxCorrection: Float = 0.5
    var maxRotation: Float = 0.3
    
    init(physicsNode: SCNNode, geometryNode: SCNNode) {
        self.physicsNode = physicsNode
        self.geometryNode = geometryNode
        
        // get initial offset
        parentOffPos = geometryNode.simdPosition
        parentOffRot = geometryNode.simdOrientation
        
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // we can make this call when the physics changes to smooth it
    // make sure its called BEFORE the physics value is changed in the rigid body
    // it works by separating the actual geometry slightly from the physics to correct for the visual pop when position is changed
    func correctPhysics(node: SCNNode, pos: SIMD3<Float>, rot: simd_quatf) {
        // find old value
        let oldTransform = geometryNode.simdWorldTransform
        
        // change position of object
        node.simdPosition = pos
        node.simdOrientation = rot
        
        physicsNode.physicsBody!.resetTransform()
        
        // restore offset
        if node != geometryNode {

            geometryNode.simdWorldTransform = oldTransform
            sourceOffPos = geometryNode.simdPosition
            sourceOffRot = geometryNode.simdOrientation
        } else {
            sourceOffPos = parentOffPos
            sourceOffRot = parentOffRot
        }
        
        // cap the maximum deltas we allow in rotation and position space
        updateSmooth(deltaTime: 1.0 / 60.0)
    }
    
    // inch geometry back to original offset from rigid body
    func updateSmooth(deltaTime: TimeInterval) {
        
        //  allow some motion up to a maximum offset
        var posDelta = parentOffPos - sourceOffPos
        if length(posDelta) > maxCorrection {
            posDelta = maxCorrection * normalize(posDelta)
        }
        // lerp pos
        let newPos = sourceOffPos + posDelta
        geometryNode.simdPosition = newPos
            
        // cap the max rotation that can show through
        let quatDelta = parentOffRot / sourceOffRot
        let angle = quatDelta.angle
        
        if angle > maxRotation {
            geometryNode.simdOrientation = simd_slerp(sourceOffRot, parentOffRot, maxRotation / angle)
        } else {
            geometryNode.simdOrientation = parentOffRot
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        updateSmooth(deltaTime: seconds)
    }
    
}
