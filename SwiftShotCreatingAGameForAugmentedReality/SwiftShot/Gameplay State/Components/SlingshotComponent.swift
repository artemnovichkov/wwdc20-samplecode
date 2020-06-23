/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages toggling physics behavior and user interaction for the slingshot.
*/

import Foundation
import GameplayKit

class SlingshotComponent: GKComponent {
    var restPos: SIMD3<Float>
    var currentPos: SIMD3<Float>
    var vel: SIMD3<Float>
    var physicsMode: Bool
    let catapult: SCNNode
    
    init(catapult: SCNNode) {
        self.catapult = catapult
        restPos = catapult.simdPosition
        currentPos = restPos
        physicsMode = false // Started off and gets turned on only if needed
        vel = SIMD3<Float>(repeating: 0.0)
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setGrabMode(state: Bool) {
        physicsMode = !state  // physics mode is off when grab mode is on
        if physicsMode {
            currentPos = catapult.simdPosition
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if physicsMode {
            // add force in direction to rest point
            let offset = restPos - currentPos
            let force = offset * 1000.0 - vel * 10.0
            
            vel += force * Float(seconds)
            currentPos += vel * Float(seconds)
            catapult.simdPosition = currentPos
            
            catapult.eulerAngles.x *= 0.9 // bring back to 0
        }
    }
}
