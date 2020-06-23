/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Vortex special effect to end the game.
*/

import Foundation
import SceneKit

protocol VortexActivationDelegate: class {
    func vortexDidActivate(_ vortex: VortexInteraction)
}

class VortexInteraction: Interaction, LeverInteractionDelegate {
    weak var delegate: InteractionDelegate?
    weak var vortexActivationDelegate: VortexActivationDelegate?
    var sfxCoordinator: SFXCoordinator?
    var musicCoordinator: MusicCoordinator?

    private var startInitialFloatTime = TimeInterval(0.0)
    private var startVortexTime = TimeInterval(0.0)

    enum State {
        case none
        case initialWait
        case animateLift
        case animateVortex
    }
    
    enum ChasmState {
        case none
        case open
        case close
    }
    
    var state: State = .none
    var chasmState: ChasmState = .none
    var isActivated: Bool { return state != .none }

    // Chasm
    private let chasmPhysics: SCNNode
//    private let chasmFire: SCNNode
    private var chasmExpandObject: SCNNode?
    private let chasmFinalScale = SIMD3<Float>(0.96, 1.0, 0.96)
    
    // Stage time
    private var timeSinceInitialFloatStart: TimeInterval { return GameTime.time - startInitialFloatTime }
    private var timeSinceVortexStart: TimeInterval { return GameTime.time - startVortexTime }

    private let liftStageStartTime = 1.0
    private let liftStageEndTime = 3.0
    
    private let vortexAnimationDuration = 11.5
    
    // Vortex Cylinder's shape represents vortex shape, and is used to animate vortex
    private var vortexCylinder: SCNNode?

    required init(delegate: InteractionDelegate) {
        self.delegate = delegate
        
        // Chasm Occluder Box: that will take over the table occluder once table occluder is removed for Vortex Interaction
        let vortex = SCNNode.loadSCNAsset(modelFileName: "chasm_animation")
        
        // Chasm
        guard let chasmPhysics = vortex.childNode(withName: "chasm", recursively: true) else { fatalError("Vortex has no chasm") }
        self.chasmPhysics = chasmPhysics
        for child in chasmPhysics.childNodes {
            if let name = child.name, name.hasPrefix("occluder") {
                child.setNodeToOccluder()
            }
        }
        chasmPhysics.simdWorldPosition = SIMD3<Float>(0.0, -0.1, 0.0) // avoid z-fight with ShadowPlane
        chasmPhysics.simdScale = chasmFinalScale
        chasmPhysics.stopAllAnimations()
    }
    
    func activate() {
        guard let delegate = delegate else { fatalError("No delegate") }
        delegate.dispatchActionToServer(gameAction: .oneHitKOPrepareAnimation)
    }

    func handle(gameAction: GameAction, player: Player) {
        guard let delegate = delegate else { fatalError("No delegate") }
        
        if case .oneHitKOPrepareAnimation = gameAction, state == .none {
            state = .initialWait
            startInitialFloatTime = GameTime.time
            
            delegate.removeTableBoxNodeFromLevel()
            delegate.removeAllPhysicsBehaviors()
            
            // Kill all catapults
            vortexActivationDelegate?.vortexDidActivate(self)
            setBlocksToNoGravity()
            
            delegate.serverDispatchActionToAll(gameAction: .oneHitKOPrepareAnimation)

            if let sfxCoordinator = sfxCoordinator {
                sfxCoordinator.playAudioFile(name: "vortex_04", volume: 0.5, loop: false)
            }
            if let musicCoordinator = musicCoordinator {
                musicCoordinator.stopCurrentMusic(fadeOut: 2.0)
            }
        }
    }

    func update(cameraInfo: CameraInfo) {
        updateVortexState()
    }
    
    private func updateVortexState() {
        switch state {
        case .none:
            break
        case .initialWait:
            if timeSinceInitialFloatStart > liftStageStartTime {
                prepareForVortexAnimationStart()
                state = .animateLift
            }
        case .animateLift:
            if timeSinceInitialFloatStart > liftStageEndTime {
                prepareForVortexAnimationEnded()
                state = .animateVortex
            }
        case .animateVortex:
            if timeSinceVortexStart < vortexAnimationDuration {
                animateVortex()
            } else {
                onVortexAnimationEnded()
                state = .none
            }
        }
    }
    
    // MARK: - Animate Vortex
    
    // Stable vortex (values found through experimentation)
    private let radialSpringConstant: Float = 100.0
    private let tangentVelocitySpringContant: Float = 40.0
    private let maxVelocity: Float = 3.0
    
    private let maxRandomVortexTorque: Float = 0.0
    private let maxRandomVortexForce = 0.2
    
    private var lastVortexCenterY: Float = 0.0
    private var lastVortexHeight: Float = 0.0
    private var lastOuterRadius: Float = 0.0
    private var lastFront = SIMD3<Float>(0.0, 0.0, -1.0)

    func animateVortex() {
        guard let delegate = delegate else { fatalError("No delegate") }
        guard let vortexCylinder = vortexCylinder else { fatalError("Vortex animation cylinder not set") }
        
        // Vortex shape from animation
        let vortexShape = vortexCylinder.presentation.simdScale
        let vortexHeightDelta = vortexShape.y - lastVortexHeight
        lastVortexHeight = vortexShape.y
        
        let vortexCenterY = vortexCylinder.presentation.simdWorldPosition.y
        let vortexCenterYDelta = vortexCenterY - lastVortexCenterY
        lastVortexCenterY = vortexCenterY
        
        // Deform shape over time
        let maxOuterRadius = vortexShape.x
        let maxInnerRadius = maxOuterRadius * 0.2 // 20 % from experiment
        let maxOuterRadiusDelta = maxOuterRadius - lastOuterRadius
        lastOuterRadius = maxOuterRadius
        
        // Orbital velocity
        let currentFront = vortexCylinder.presentation.simdWorldFront
        let orbitalMoveDelta = length(currentFront - lastFront) * maxInnerRadius
        lastFront = currentFront

        let orbitalVelocityFactor: Float = 5.0
        let orbitalVelocity = (orbitalMoveDelta / Float(GameTime.deltaTime)) * orbitalVelocityFactor
        
        let topBound = vortexCenterY + vortexShape.y * 0.5
        let bottomBound = vortexCenterY - vortexShape.y * 0.5
        
        let blockObjects = delegate.allBlockObjects
        let up = SIMD3<Float>(0.0, 1.0, 0.0)
        for block in blockObjects {
            guard let physicsNode = block.physicsNode, let physicsBody = physicsNode.physicsBody else { continue }
            
            let position = physicsNode.presentation.simdWorldPosition
            let positionWithoutY = SIMD3<Float>(position.x, 0.0, position.z)
            let distanceFromCenter = length(positionWithoutY)
            let directionToCenter = -normalize(positionWithoutY)
            
            // Adjust radius into curve
            // Equation representing a half radius chord of circle equation
            let normalizedY = clamp(position.y / topBound, 0.0, 1.0)
            var radiusFactor = sqrtf(4.0 - 3.0 * normalizedY * normalizedY) - 1.0
            radiusFactor = radiusFactor * 0.8 + 0.2
            let innerRadius = maxInnerRadius * radiusFactor
            let outerRadius = maxOuterRadius * radiusFactor
            
            // Cap velocity
            let maxVelocity: Float = 30.0
            if length(physicsBody.simdVelocity) > maxVelocity {
                physicsBody.simdVelocity = normalize(physicsBody.simdVelocity) * maxVelocity
            }
            
            var force = SIMD3<Float>()

            // Stage specific manipulation
            let vortexDirection = cross(directionToCenter, up)
            let speedInVortexDirection = dot(physicsBody.simdVelocity, vortexDirection)

            // Stable vortex pull
            let pullForceMagnitude = (speedInVortexDirection * speedInVortexDirection) * Float(physicsBody.mass) / distanceFromCenter
            force += pullForceMagnitude * directionToCenter

            // Pull into outer radius
            let radialInwardForceMagnitude = radialSpringConstant * max(0.0, distanceFromCenter - outerRadius)
            force += radialInwardForceMagnitude * directionToCenter

            // Pull away from inner radius
            let radialOutwardForceMagnitude = radialSpringConstant * max(0.0, innerRadius - distanceFromCenter)
            force += -radialOutwardForceMagnitude * directionToCenter

            // Vortex velocity adjustment
            if distanceFromCenter > innerRadius {
                let tangentForceMagnitude = tangentVelocitySpringContant * (speedInVortexDirection - orbitalVelocity)
                force += -tangentForceMagnitude * vortexDirection * (0.5 + Float(drand48() * 1.0))
            }
            
            // Random forces/torque
            force += length(force) * Float((drand48() * 2.0 - 1.0) * maxRandomVortexForce) * up
            applyRandomTorque(physicsBody: physicsBody, maxTorque: maxRandomVortexTorque)

            // Top bound pull down
            let topBoundForceMagnitude = radialSpringConstant * max(0.0, position.y - topBound)
            force += topBoundForceMagnitude * -up

            // Bottom bound pull up
            let bottomBoundForceMagnitude = radialSpringConstant * max(0.0, bottomBound - position.y)
            force += bottomBoundForceMagnitude * up
            
            physicsBody.applyForce(force, asImpulse: false)
            
            // Scale the vortex
            // The higher position in the bound, more it should move upward to scale the vortex
            let normalizedPositionInBoundY = clamp((position.y - bottomBound) / vortexShape.y, 0.0, 1.0)
            let heightMoveFactor = abs(normalizedPositionInBoundY - 0.5)
            let newPositionY = position.y + vortexCenterYDelta + vortexHeightDelta * heightMoveFactor

            let positionXZ = SIMD3<Float>(position.x, 0.0, position.z)
            let radialMoveFactor = clamp(distanceFromCenter / outerRadius, 0.0, 1.0)
            let newPositionXZ = positionXZ + maxOuterRadiusDelta * radialMoveFactor * -directionToCenter

            physicsNode.simdWorldPosition = SIMD3<Float>(newPositionXZ.x, newPositionY, newPositionXZ.z)
            physicsNode.simdWorldOrientation = physicsNode.presentation.simdWorldOrientation
            physicsBody.resetTransform()
        }
    }

    func handleTouch(_ type: TouchType, camera: Ray) {

    }
    
    // MARK: - Prepare for Vortex
    
    private let maxInitialImpulse: Float = 3.0
    private let maxInitialTorque: Float = 1.0 // Found through experimentation

    private func setBlocksToNoGravity() {
        enumerateThroughBlocks { physicsBody in
            physicsBody.isAffectedByGravity = false
        }
    }
    
    private func prepareForVortexAnimationStart() {
        enumerateThroughBlocks { physicsBody in
            physicsBody.isAffectedByGravity = false
            let initialImpulse = maxInitialImpulse * Float(drand48() * 0.7 + 0.3)
            physicsBody.applyForce(SIMD3<Float>(0.0, initialImpulse, 0.0), asImpulse: true)

            applyRandomTorque(physicsBody: physicsBody, maxTorque: maxInitialTorque)

            physicsBody.damping = 0.4
        }
    }
    
    private func prepareForVortexAnimationEnded() {
        guard let delegate = delegate else { fatalError("No Delegate") }
        enumerateThroughBlocks { physicsBody in
            physicsBody.damping = 0.1
        }
        
        // Chasm Expand Object (used for animation)
        let vortex = SCNNode.loadSCNAsset(modelFileName: "chasm_animation")
        guard let vortexCylinder = vortex.childNode(withName: "Cylinder", recursively: true) else { fatalError("Vortex has no cone") }
        
        self.vortexCylinder = vortexCylinder
        delegate.addNodeToLevel(vortexCylinder)
        vortexCylinder.stopAllAnimations()
        vortexCylinder.playAllAnimations()
        vortexCylinder.isHidden = true // Vortex Cylinder is only used for deriving the vortex shape animation
        
        // Chasm Expand Object (used for animation)
        guard let chasmExpandObject = vortex.childNode(withName: "chasm", recursively: true) else { fatalError("Vortex has no chasm") }
        for child in chasmExpandObject.childNodes {
            if let name = child.name, name.hasPrefix("occluder") {
                child.setNodeToOccluder()
            }
        }
        self.chasmExpandObject = chasmExpandObject
        delegate.addNodeToLevel(chasmExpandObject)
        chasmExpandObject.stopAllAnimations()
        chasmExpandObject.playAllAnimations()

        let vortexShape = vortexCylinder.presentation.simdScale
        lastOuterRadius = vortexShape.x
        lastVortexCenterY = vortexCylinder.presentation.simdWorldPosition.y
        lastVortexHeight = vortexShape.y
        lastFront = vortexCylinder.presentation.simdWorldFront
        
        startVortexTime = GameTime.time
    }
    
    private func onVortexAnimationEnded() {
        // Remove or hide everything
        vortexCylinder?.stopAllAnimations()
        vortexCylinder?.removeFromParentNode()
        chasmExpandObject?.removeFromParentNode()
        
        guard let delegate = delegate else { fatalError("No delegate") }
        let blockObjects = delegate.allBlockObjects
        for block in blockObjects {
            block.objectRootNode.isHidden = true
        }
    }
    
    private func enumerateThroughBlocks(physicsFunction: (SCNPhysicsBody) -> Void) {
        guard let delegate = delegate else { fatalError("No delegate") }
        
        let blockObjects = delegate.allBlockObjects
        for block in blockObjects {
            if let physicsNode = block.physicsNode, let physicsBody = physicsNode.physicsBody {
                physicsFunction(physicsBody)
            }
        }
    }
    
    // MARK: - Helper Function
    
    private func applyRandomTorque(physicsBody: SCNPhysicsBody, maxTorque: Float) {
        var randomAxis = SIMD3<Float>(Float(drand48()), Float(drand48()), Float(drand48()))
        randomAxis = normalize(randomAxis)
        let randomTorque = SIMD4<Float>(randomAxis, Float(drand48() * 2.0 - 1.0) * maxTorque)
        physicsBody.applyTorque(randomTorque, asImpulse: true)
    }
    
    private func stageProgress(startTime: TimeInterval, endTime: TimeInterval) -> Float {
        let progress = Float((timeSinceInitialFloatStart - startTime) / (endTime - startTime))
        return clamp(progress, 0.0, 1.0)
    }
}
