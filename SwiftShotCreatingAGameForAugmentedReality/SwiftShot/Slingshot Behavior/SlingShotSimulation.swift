/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages the simulation for the slingshot rope.
*/

import Foundation
import SceneKit
import simd

// Provides access to most variables used to describe the simulation parameters as well as
// the management of the SceneKit rigid bodies.
class SlingShotSimulation: NSObject {
    
    let linearLaunchAnimationTime = 0.5
    let simLaunchAnimationTime = 2.5  // needs more time to settle
    
    var simDamping: Float = 0.85 // the amount of damping to apply to the rigid 5odies
    var simBounce: Float = 0.0 // the amount of restitution to apply to the rigid bodies
    var simShotStrength: Float = 20.0 // the strength of the shot when released
    var simNeighborStrength: Float = 350 // the strength for the neighbor springs
    var simRestPoseStrength: Float = 5 // the strength for the restpose force
    var simBlend: Float = 0.08 // the amount of lerp to restPose per iteration,
                               // higher ends faster, related to finishing sim before simLaunchAnimationTime expires
    
    // the collision plane distance
    var collisionPlane: Float = 0.15 // using half depth of catatpult at 0.25 / 2 ~ 0.125 + slop
    
    // smoothing the rope from 0 to 1
    var smoothRope: Float = 0.25

    // ignore these bones
    // weight the vertices at the edge of the rope on first/last bone 100% to avoid cord pulling out
    let boneInset = 1
    
    struct SimulatedTransform {
        var position: SIMD3<Float>
        var orientation: simd_quatf
        var velocity: SIMD3<Float>
        var dynamic: Bool
    }

    var originalTotalLength: Float = 100.0 // defines the original (unstretched) length of the rope
    var originalLeatherLength: Float = 45.0 // defines the original (unstretched) length of the leather portion of the rope

    // the parent space of the slingshot
    var restPoseSpace = float4x4() {
        didSet {
            dirtyCachedValues()
        }
    }
    private var originalRestPoseSpace = float4x4()
    private var restPoseTransforms = [float4x4]()

    // the rest pose of the slingshot in world space
    var restPose: SlingShotPose {
        return computedRestPose.value
    }
    private lazy var computedRestPose = ComputedValue<SlingShotPose> { [unowned self] in
        
        let data = SlingShotPose()
        
        for i in 0...self.restPoseTransforms.count - 1 {
            
            let transform = self.restPoseSpace * self.restPoseTransforms[i]
            let p = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            let t = simd_quatf(transform).act(SIMD3<Float>(1, 0, 0))
            
            var l: Float = 0.0
            if i > 0 {
                l = data.lengths[i - 1] + length(p - data.positions[i - 1])
            }
            
            data.positions.append(p)
            data.tangents.append(t)
            data.lengths.append(l)
        }
        
        return data
    }

    var fixturePositionL: SIMD3<Float> {
        return restPose.positions.first!
    }

    var fixturePositionR: SIMD3<Float> {
        return restPose.positions.last!
    }
    
    var upVector: SIMD3<Float> {
         return simd_quatf(restPoseSpace).act(SIMD3<Float>(0, 1, 0))
    }
    
    // return the number of simulated transforms in this slingshot
    var simulatedTransformCount: Int {
        return simulatedTransforms.count
    }

    // returns a simulated transform within this simulation
    func simulatedTransform(_ index: Int) -> SimulatedTransform {
        return simulatedTransforms[index]
    }

    // returns a simulated transform within this simulation as float4x4
    func simulatedTransformAsFloat4x4(_ index: Int) -> float4x4 {
        let mSim = simulatedTransforms[index]
        var m = float4x4(mSim.orientation)
        m.columns.3 = SIMD4<Float>(mSim.position, 1.0)
        return m
    }

    private var simulatedTransforms: [SimulatedTransform] = [SimulatedTransform]()
    
    private var time: TimeInterval = 0

    // the position of the ball - used to compute the input pose.
    var ballPosition = SIMD3<Float>(0, 0, -175) {
        didSet {
            dirtyCachedValues()
        }
    }

    // the radius of the ball - used to compute the input pose
    var ballRadius: Float = 6.0 {
        didSet {
            dirtyCachedValues()
        }
    }

    // the position on the left side of the ball where the straight part of the rope touches
    private var tangentPositionL: SIMD3<Float> {
        return computedTangentPositionL.value
    }
    private lazy var computedTangentPositionL = ComputedValue<SIMD3<Float>> { [unowned self] in
        return self.tangentPosition(self.fixturePositionL)
    }

    // the position on the right side of the ball where the straight part of the rope touches
    private var tangentPositionR: SIMD3<Float> {
        return computedTangentPositionR.value
    }
    private lazy var computedTangentPositionR = ComputedValue<SIMD3<Float>> { [unowned self] in
        return self.tangentPosition(self.fixturePositionR)
    }

    // the center position within the triangle spanned by the ball and both fixture positions
    private var centerPosition: SIMD3<Float> {
        return computedCenterPosition.value
    }
    private lazy var computedCenterPosition = ComputedValue<SIMD3<Float>> { [unowned self] in
        let direction = cross(self.upVector, self.tangentPositionR - self.tangentPositionL)
        return self.ballPosition - normalize(direction) * 1.25 * self.ballRadius
    }

    // the angle of the arc portion of the rope touching the ball
    private var betaAngle: Float {
        return computedBetaAngle.value
    }
    private lazy var computedBetaAngle = ComputedValue<Float> { [unowned self] in
        let d = normalize(self.ballPosition - self.centerPosition)
        let t = normalize(self.tangentPositionL - self.ballPosition)
        return 2.0 * simd_quatf(from: d, to: t).angle
    }

    // the resulting input pose of the sling shot rope
    var inputPose: SlingShotPose {
        return computedInputPose.value
    }
    private lazy var computedInputPose = ComputedValue<SlingShotPose> { [unowned self] in self.computeInputPose() }
    private func computeInputPose() -> SlingShotPose {
        // note the -1 here differs from other usage
        let data = SlingShotPose()
        data.upVector = -upVector // negated because the strap Y-axis points down
        
        let startBend = currentLengthL / currentTotalLength
        let endBend = 1.0 - currentLengthR / currentTotalLength
        let leatherOnStraights = originalLeatherLength - currentLengthOnBall
        let segmentAStart: Float = 0.0
        let segmentAEnd = currentLengthL - leatherOnStraights * 0.5
        let segmentCStart = segmentAEnd + originalLeatherLength
        let segmentCEnd = currentTotalLength
        let originalLeatherRange = originalLeatherLength / originalTotalLength
        let currentLeatherRange = originalLeatherLength / currentTotalLength
        
        for i in 0...simulatedTransformCount - 1 {
            
            let l: Float = originalTotalLength * Float(i) / Float(simulatedTransformCount - 1)
            var u = l / originalTotalLength
            
            // remap the u value depending on the material (rubber vs leather)
            let isRubber = abs(0.5 - u) > originalLeatherRange * 0.5
            if isRubber {
                if u < 0.5 {
                    u = u / (0.5 - originalLeatherRange * 0.5)
                    u = (segmentAStart + (segmentAEnd - segmentAStart) * u) / currentTotalLength
                } else {
                    u = 1.0 - (1.0 - u) / (0.5 - originalLeatherRange * 0.5)
                    u = (segmentCStart + (segmentCEnd - segmentCStart) * u) / currentTotalLength
                }
            } else {
                u = (startBend + endBend) * 0.5 - (0.5 - u) * (currentLeatherRange / originalLeatherRange)
            }
            
            var p = SIMD3<Float>(0, 0, 0)
            var t = SIMD3<Float>(1, 0, 0)
            if u < startBend { // left straight
                p = mix(fixturePositionL, tangentPositionL, t: SIMD3<Float>(repeating: u / startBend)) // left rubber band
                t = normalize(tangentPositionL - fixturePositionL)
            } else if u > endBend { // right straight
                p = mix(fixturePositionR, tangentPositionR, t: SIMD3<Float>(repeating: ( 1.0 - u ) / ( 1.0 - endBend ))) // right rubber band
                t = normalize(fixturePositionR - tangentPositionR)
            } else { // on the ball
                let upv = upVector
                let rot = simd_quatf(angle: -betaAngle * (u - startBend) / ( endBend - startBend), axis: upv)
                p = ballPosition + rot.act(tangentPositionL - ballPosition)
                t = cross(upv, normalize(ballPosition - p))
            }
            
            data.positions.append(p)
            data.tangents.append(t)
            data.lengths.append(l)
        }
        return data
        
    }

    init(rootNode: SCNNode, count: Int, segmentRadius: Float) {
        super.init()
        for i in 0..<count {
            let isStatic = (i < boneInset) || (i >= count - boneInset)
            let p = SIMD3<Float>(0, 0, 0)
            let q = simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0))
            let v = SIMD3<Float>(0, 0, 0)
            let transform = SimulatedTransform(position: p, orientation: q, velocity: v, dynamic: !isStatic)

            simulatedTransforms.append(transform)
        }
    }
    
    // mark all computed values as dirty - to force a recompute
    private func dirtyCachedValues() {
        computedTangentPositionL.isDirty = true
        computedTangentPositionR.isDirty = true
        computedCenterPosition.isDirty = true
        computedBetaAngle.isDirty = true
        computedInputPose.isDirty = true
        computedRestPose.isDirty = true
    }

    // computes the tangent position of the rope based on a given fixture
    private func tangentPosition(_ fixture: SIMD3<Float>) -> SIMD3<Float> {
        let r = ballRadius
        var d = fixture - ballPosition
        let alpha = acos(r / length(d))
        d = ballRadius * normalize(d)
        let rot = simd_quatf(angle: fixture == fixturePositionL ? -alpha : alpha, axis: upVector)
        let d_rotated = rot.act(d)
        return d_rotated + ballPosition
    }

    // sets the initial rest pose of the slingshot, all args are in global space
    func setInitialRestPose(_ slingshotSpace: float4x4, _ transforms: [float4x4]) {
        
        originalRestPoseSpace = slingshotSpace
        restPoseSpace = slingshotSpace
        
        restPoseTransforms = [float4x4]()
        
        for i in 0..<transforms.count {
            restPoseTransforms.append(originalRestPoseSpace.inverse * transforms[i])
        }

        computedRestPose.isDirty = true
    }
    
    // sets the initial rest pose from a series of scenekit nodes
    func setInitialRestPose(_ slingshotBase: SCNNode, _ bones: [SCNNode]) {
        
        let space = slingshotBase.simdWorldTransform
    
        var transforms = [float4x4]()
        for i in 0..<bones.count {
            transforms.append(bones[i].simdWorldTransform)
        }
        
        setInitialRestPose(space, transforms)
    }
    
    // returns the orientation of the ball in world space
    var ballOrientation: simd_quatf {
        let x = normalize(centerPosition - ballPosition)
        let y = upVector
        let z = cross(x, y)
        let rot = simd_float3x3(x, y, z)
        return simd_quatf(rot)
    }
    
    // returns the length of the rope touching the ball
    var currentLengthOnBall: Float {
        return betaAngle * ballRadius
    }
    
    // returns the length of the straight portion of the rope on the left side of the ball
    var currentLengthL: Float {
        return length(tangentPositionL - fixturePositionL)
    }

    // returns the length of the straight portion of the rope on the right side of the ball
    var currentLengthR: Float {
        return length(tangentPositionR - fixturePositionR)
    }

    // returns the current total length of the rope
    var currentTotalLength: Float {
        return currentLengthL + currentLengthOnBall + currentLengthR
    }
    
    // returns the interpolated transform on the restpose given a length l (from 0.0 to originalTotalLength)
    func restPoseTransform(_ l: Float) -> float4x4 {
        
        if currentTotalLength == 0.0 {
            return float4x4()
        }
        let normalizedL = restPose.totalLength * l / originalTotalLength
        return restPose.transform(at: normalizedL)
    }
    
    // returns the interpolated transform on the input pose given a length l (from 0.0 to currentTotalLength)
    func inputPoseTransform(_ l: Float) -> float4x4 {
        
        if currentTotalLength == 0.0 {
            return float4x4()
        }
        return inputPose.transform(at: l)
    }
    
    func interpolateToRestPoseAnimation(_ duration: TimeInterval, _ ropeShapes: [SCNNode]) {
        // use relative tr[ansforms here, these are safer when the catapult gets hit
        if duration == 0 {
            for i in boneInset..<ropeShapes.count - boneInset {
                ropeShapes[i].simdWorldTransform = restPoseSpace * restPoseTransforms[i]
            }
        } else {
            SCNTransaction.animate(duration: duration, animations: {
                for i in boneInset..<ropeShapes.count - boneInset {
                    ropeShapes[i].simdWorldTransform = restPoseSpace * restPoseTransforms[i]
                }
            })
        }
    }
    
    // disables the simulation on the slingshot and sets the rigid bodies to be driven by the input pose
    func enableInputPose() {
        
        for i in 0..<simulatedTransforms.count {

            let l = originalTotalLength * Float(i) / Float(simulatedTransforms.count - 1)
            let transform = inputPoseTransform(l)

            let p = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            simulatedTransforms[i].position = p
            simulatedTransforms[i].orientation = simd_quatf(transform)
            simulatedTransforms[i].velocity = SIMD3<Float>(repeating: 0)
            simulatedTransforms[i].dynamic = false
        }
    }
    
    // starts the simulation for the slingshot
    func startLaunchSimulation() {
        
        let center = (fixturePositionL + fixturePositionR) * 0.5
        let force = center - ballPosition
        let strength: Float = simShotStrength
        
        for i in boneInset..<simulatedTransforms.count - boneInset {

            simulatedTransforms[i].dynamic = true

            // apply a force
            let u = Float(i) / Float(simulatedTransforms.count - 1)
            let restPoseFactorAlongRope = 1.0 - abs(u - 0.5) / 0.5
            
            simulatedTransforms[i].velocity = force * restPoseFactorAlongRope * strength
        }
    }
    
    // computes and applies the custom forces for the slingshot rope.
    // this should be called every frame.
    private func applyForces() {
        
        let b = SIMD3<Float>(repeating: simBlend)
        
        for i in boneInset..<simulatedTransforms.count - boneInset {
            
            if !simulatedTransforms[i].dynamic {
                continue
            }

            var force = SIMD3<Float>()
            
            if i > 0 {
                let restA = restPose.positions[i - 1]
                let restB = restPose.positions[i]
                let currentA = simulatedTransforms[i - 1].position
                let currentB = simulatedTransforms[i].position
                let restDistance = length(restA - restB)
                let currentDistance = length(currentA - currentB)
                force += normalize(currentA - currentB) * (currentDistance - restDistance) * simNeighborStrength
            }
            if i < simulatedTransforms.count - 1 {
                let restA = restPose.positions[i + 1]
                let restB = restPose.positions[i]
                let currentA = simulatedTransforms[i + 1].position
                let currentB = simulatedTransforms[i].position
                let restDistance = length(restA - restB)
                let currentDistance = length(currentA - currentB)
                force += normalize(currentA - currentB) * (currentDistance - restDistance) * simNeighborStrength
            }
            
            force += (restPose.positions[i] - simulatedTransforms[i].position) * simRestPoseStrength
            
            let vel = simulatedTransforms[i].velocity
            simulatedTransforms[i].velocity = mix(vel, force, t: b)
        }
    }

    private func averageVelocities() {
   
        var currentTransforms = [SimulatedTransform]()
        currentTransforms.append(contentsOf: simulatedTransforms)
        
        for i in boneInset..<simulatedTransformCount - boneInset {
            
            if !simulatedTransforms[i].dynamic {
                continue
            }
            
            let a = currentTransforms[i - 1].velocity
            let b = currentTransforms[i].velocity
            let c = currentTransforms[i + 1].velocity
            let ab = mix(a, b, t: [0.5, 0.5, 0.5])
            let bc = mix(b, c, t: [0.5, 0.5, 0.5])
            simulatedTransforms[i].velocity = mix(ab, bc, t: [0.5, 0.5, 0.5])
        
            let center = mix(currentTransforms[i - 1].position, currentTransforms[i + 1].position, t: [0.5, 0.5, 0.5])
            simulatedTransforms[i].position = mix(simulatedTransforms[i].position, center, t: SIMD3<Float>(repeating: smoothRope))
        }
    }

    private func performPlaneCollision(_ previousTransforms: [SimulatedTransform], _ seconds: Float) {
        
        for i in boneInset..<simulatedTransforms.count - boneInset {
            
            if !simulatedTransforms[i].dynamic {
                continue
            }
            
            var p = simulatedTransforms[i].position
            var v = simulatedTransforms[i].velocity
            
            // project into the space of the base
            var pM = float4x4(translation: p)
            
            var pLocal = restPoseSpace.inverse * pM
            if pLocal.columns.3.z <= collisionPlane {
                pLocal.columns.3.z = collisionPlane
                pM = restPoseSpace * pLocal
                
                let pOnPlane = SIMD3<Float>(pM.columns.3.x, pM.columns.3.y, pM.columns.3.z)
                
                let blend = SIMD3<Float>(repeating: 0.3)
                simulatedTransforms[i].position = mix(p, pOnPlane, t: blend)
                
                var correctedVelocity = (simulatedTransforms[i].position - previousTransforms[i].position) / seconds
                correctedVelocity *= SIMD3<Float>(0.7, 0.1, 0.7)
                
                // verlet integration
                simulatedTransforms[i].velocity = mix(v, correctedVelocity, t: blend)
                
                p = simulatedTransforms[i].position
                v = simulatedTransforms[i].velocity
            }
            
            if pLocal.columns.3.y <= collisionPlane + 0.3 {
                pLocal.columns.3.y = collisionPlane + 0.3
                pM = restPoseSpace * pLocal
                
                let pOnPlane = SIMD3<Float>(pM.columns.3.x, pM.columns.3.y, pM.columns.3.z)
                
                let blend = SIMD3<Float>(repeating: Float(0.3))
                simulatedTransforms[i].position = mix(p, pOnPlane, t: blend)
                
                let correctedVelocity = (simulatedTransforms[i].position - previousTransforms[i].position) / seconds
                
                // verlet integration
                simulatedTransforms[i].velocity = mix(v, correctedVelocity, t: blend)
            }
            
        }
    }
    
    // aligns the rigid bodies by correcting their orienation
    // this should be called after the simulation step
    private func alignBones() {
        
        // orient the bodies accordingly
        for i in boneInset..<simulatedTransforms.count - boneInset {
            
            if !simulatedTransforms[i].dynamic {
                continue
            }

            let a = simulatedTransforms[i - 1].position
            let b = simulatedTransforms[i + 1].position

            // this is the upVector computed for each bone of the rest pose
            let transform = restPoseSpace * restPoseTransforms[i] // todo: direction of multiply?
            var y = simd_quatf(transform).act(SIMD3<Float>(0, 1, 0))
           
            let x = normalize(b - a)
            let z = normalize(cross(x, y))
            y = normalize(cross(z, x))
            
            let rot = simd_float3x3(x, y, z)
            simulatedTransforms[i].orientation = simd_quatf(rot)
        }
    }

    func simulateStep(time: TimeInterval) {
        
        let minUpdateSeconds: Float = 1.0 / 120.0
        let maxUpdateSeconds: Float = 1.0 / 30.0
        let seconds = clamp(Float(time - self.time), minUpdateSeconds, maxUpdateSeconds)

        // could run multiple iterations if greater than maxUpdateSeconds, but for now just run one
        
        applyForces()
        averageVelocities()
        
        // copy the current state
        var currentTransforms = [SimulatedTransform]()
        currentTransforms.append(contentsOf: simulatedTransforms)

        // simulate forward
        for i in boneInset..<simulatedTransforms.count - boneInset {
            
            if !currentTransforms[i].dynamic {
                continue
            }
            
            var p = currentTransforms[i].position
            let v = currentTransforms[i].velocity
            p += v * seconds
            
            simulatedTransforms[i].position = p
        }
        
        performPlaneCollision(currentTransforms, seconds)
        alignBones()
        
        self.time = time
    }
}
