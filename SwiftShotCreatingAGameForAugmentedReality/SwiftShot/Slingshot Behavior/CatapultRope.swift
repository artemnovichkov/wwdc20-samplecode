/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages the slingshot animation.
*/

import simd
import SceneKit

class CatapultRope {
    private let rope: SlingShotSimulation
    
    private let numStrapBones = 35
    
    // hold onto the rope shapes, will copy transforms into these
    private var ropeShapes = [SCNNode]()
    private let base: SCNNode
    
    private var animatingLaunchTimestamp: TimeInterval = 0.0
    
    private var savedRopeShapeTransform = [float4x4]()
    
    enum State {
        case none
        case move
        case launch
    }
    
    private var state: State = .none
    
    init(_ base: SCNNode) {
        self.base = base
        
        // setup the rope simulation
        // segmentRadius is size of the rigid bodies that represent the rope
        rope = SlingShotSimulation(rootNode: base, count: numStrapBones, segmentRadius: 0.02 * 5)
   
        // this will be set when projectile set onto catapult
        rope.ballRadius = 0.275
        
        // the projectile is resting atop the strap when inactive, will it settle okay
        // what about the orient of the projectile
        // The ball will jump as the strap is pulled
        
        rope.ballPosition = base.childNode(withName: "ballOriginInactiveBelow", recursively: true)!.simdWorldPosition
        
        // grab an array of each bone from the rig, these are called sling0...sling<count>
        // these are in the inactive strap
        var originalTotalLength: Float = 0
        var originalLeatherLength: Float = 0
        for i in 0..<numStrapBones {
            ropeShapes.append(base.childNode(withName: "strap\(i)", recursively: true)!)
            if i > 1 {
                // estimate with linear length
                let delta = length(ropeShapes[i].simdWorldPosition - ropeShapes[i - 1].simdWorldPosition)
                originalTotalLength += delta
                if i >= 13 && i <= 21 {
                    originalLeatherLength += delta
                }
            }
        }
        
        rope.originalTotalLength = originalTotalLength
        rope.originalLeatherLength = originalLeatherLength
        
        rope.setInitialRestPose(base, ropeShapes)
    }
    
    public func setBallRadius(_ ballRadius: Float) {
        rope.ballRadius = ballRadius
    }
    
    public func grabBall(_ ballPosition: SIMD3<Float>) {
        moveBall(ballPosition)
    }
    
    public func moveBall(_ ballPosition: SIMD3<Float>) {
        
        // grab must be called prior, and it sets .move mode up
        state = .move
        rope.ballPosition = ballPosition
        
        // this is really the currently rotated space of the base
        rope.restPoseSpace = base.simdWorldTransform
        
        // disables simulation, sets mask to zero, and drives it by the rig
        rope.enableInputPose()
    }

    var useSim = true
    
    public func launchBall() {
        state = .launch
        animatingLaunchTimestamp = GameTime.time
        
        useSim = UserDefaults.standard.showRopeSimulation
        
        // this lets the rope fly
        if useSim {
            rope.startLaunchSimulation()
        } else {
            interpolateToRestPoseAnimation(rope.linearLaunchAnimationTime)
        }
    }
    
    public func interpolateToRestPoseAnimation(_ duration: TimeInterval) {
        rope.interpolateToRestPoseAnimation(duration, ropeShapes)
    }

    // called at start of render phase, but before render scaling
    public func updateRopeModel() {
        if state == .none || (!useSim && state == .launch) { return }
        
        let time = GameTime.time
        
        // this advances by at most a fixed timestep
        rope.simulateStep(time: time)
        
        // copy the bone locations back to the rig
        // don't change the begin and end bones, those are static and will separate if changed
        for i in rope.boneInset..<numStrapBones - rope.boneInset {
            // presentation node actually has the results of the simulation
            ropeShapes[i].simdWorldTransform = rope.simulatedTransformAsFloat4x4(i)
        }
        
        // reset the animation state back to none
        // this can't be longer than the cooldownTime - grow/drop time (around 2.5s)
        // but has to be long enough to let the rope sim settle back to reset pose
        let delta = time - animatingLaunchTimestamp
        if state == .launch && delta >= rope.simLaunchAnimationTime {
            state = .none
        }
    }
}
