/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Input System
*/

import Foundation
import UIKit
import ARKit
import RealityKit
import Combine
import CoreMotion

class InputSystem: UIGestureRecognizer {
    public var arView: ARView!

    // Touch input variables
    private var panVelocity = SIMD2<Float>.zero
    private var previousTouchPosition: CGPoint!

    // Whack variables
    private let whackTimeout = 0.75
    private var whackTime = 0.0
    private var previousZAcceleration = 0.0
    private let motion = CMMotionManager()

    // The Tractor Beam allows you to carry a creature around with you
    private var carriedCreature: CreatureEntity?
    private let cameraCarryOffset: SIMD3<Float> = [0, 0, 0.4]

    private let flingVelocityMetersPerPoint: Float

    public weak var inputSystemDelegate: InputSystemDelegate?

    override init(target: Any?, action: Selector?) {
        // calculate screen space (points) to world space (meters) conversion based on this device
        flingVelocityMetersPerPoint = Constants.flingVerticalScale / Float(UIScreen.main.bounds.height)
        super.init(target: target, action: action)
        motion.accelerometerUpdateInterval = 1.0 / Double(Constants.accelerometerFramesPerSecond)
        motion.startAccelerometerUpdates()
    }

    public func setupDependencies(arView: ARView) {
        self.arView = arView
        previousTouchPosition = arView.center
    }

    public func updateLoop() {
        // Maintain Whack indicator light
        checkForWhack()
    }

    override func reset() {
        super.reset()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        // Initialize this new touch
        let touchStartPosition = touch.location(in: view)
        previousTouchPosition = touchStartPosition
        panVelocity = .zero

        // Check if we are using the tractor beam
        checkForTractorBeam(touchStartPosition)

        // Check if we can perform any secondary tap action
        guard let surfaceTransform = surfaceTransformFromTouchPosition() else { return }
        inputSystemDelegate?.playerBeganTouch(touchTransform: surfaceTransform)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let currentTouchPosition = touch.location(in: view)

        // Track pan velocity from position delta. Note: Screen is (0,0) in top left corner
        panVelocity.x = Float(currentTouchPosition.x) - Float(previousTouchPosition?.x ?? 0)
        panVelocity.y = -1 * (Float(currentTouchPosition.y) - Float(previousTouchPosition?.y ?? 0))
        previousTouchPosition = currentTouchPosition
        // If you're not carrying a creature, you may engage the touch trail
        if carriedCreature == nil {
            updateTouchTrail()
        }
    }

    func updateTouchTrail() {
        guard let surfaceTransform = surfaceTransformFromTouchPosition() else { return }
        inputSystemDelegate?.playerUpdatedTouchTrail(touchTransform: surfaceTransform)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        onTouchInputEnd()
        reset()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        onTouchInputEnd()
        reset()
    }

    func onTouchInputEnd() {
        guard let creature = carriedCreature else { return }

        // Fling or Drop a Creature you were Beaming
        if creature.currentState == .tractorBeamed ||
            creature.currentState == .tractorBeamReelIn {
            // Fling it!
            if panVelocity.magnitude() > 0 {
                // The more upward the swipe, the more it's meant to travel depth-wise
                let swipeUpwardness = simd.dot(normalize(panVelocity),
                                               SIMD2<Float>(0, 1))
                let swipeRightness = simd.dot(normalize(panVelocity),
                                              SIMD2<Float>(1, 0))
                // This magnitude is in points. We are operating in worldspace. Therefore,
                // we use this scalar value to convert to meters and then add a "feel" scale
                // factor
                let swipeMagnitude = panVelocity.magnitude() * flingVelocityMetersPerPoint

                let forwardVector = normalize(arView.cameraTransform.matrix.forwardVector)
                let upwardVector = normalize(arView.cameraTransform.matrix.upVector)
                let rightVector = normalize(arView.cameraTransform.matrix.rightVector)

                let forwardComponent = (forwardVector * swipeUpwardness * swipeMagnitude)
                let upwardComponent = (upwardVector * swipeUpwardness * swipeMagnitude)
                let rightwardComponent = (rightVector * swipeRightness * swipeMagnitude)
                var panVelocity3d = forwardComponent + upwardComponent + rightwardComponent

                // We don't want to add vertical force if the device is looking directly at
                // the floor, or directly at the ceiling. Dot product scales that nicely for us.
                panVelocity3d.y *= abs(dot(upwardVector, SIMD3<Float>(0, 1, 0)))
                creature.release(gestureVelocity: panVelocity3d * Options.flingStrengthMultiplier.value)
            } else {
                // Drop it!
                creature.release(gestureVelocity: .zero)
            }
            inputSystemDelegate?.playerEndedTouch()
        }
        carriedCreature = nil
    }

    public func worldspaceTouchPosition() -> SIMD3<Float> {
        cgPointToWorldspace(previousTouchPosition,
                            offsetFromCamera: cameraCarryOffset)
    }

    func cgPointToWorldspace(_ cgPoint: CGPoint, offsetFromCamera: SIMD3<Float>) -> SIMD3<Float> {
        // Get position of camera plane
        let camForwardPoint = arView.cameraTransform.matrix.position +
            (arView.cameraTransform.matrix.forwardVector * offsetFromCamera.z)
        var col0 = SIMD4<Float>(1, 0, 0, 0)
        var col1 = SIMD4<Float>(0, 1, 0, 0)
        var col2 = SIMD4<Float>(0, 0, 1, 0)
        var col3 = SIMD4<Float>(camForwardPoint.x, camForwardPoint.y, camForwardPoint.z, 1)
        let planePosMatrix = float4x4(col0, col1, col2, col3)

        // Get initial rotation of camera plane
        let camRotMatrix = float4x4(arView.cameraTransform.rotation)

        // Get rotation offset: Y-up is considered the plane's normal, so we
        // rotate the plane around its X-axis by 90 degrees.
        col0 = SIMD4<Float>(1, 0, 0, 0)
        col1 = SIMD4<Float>(0, 0, 1, 0)
        col2 = SIMD4<Float>(0, -1, 0, 0)
        col3 = SIMD4<Float>(0, 0, 0, 1)
        let axisFlipMatrix = float4x4(col0, col1, col2, col3)

        let rotatedPlaneAtPoint = planePosMatrix * camRotMatrix * axisFlipMatrix
        let projectionAtRotatedPlane = arView.unproject(cgPoint, ontoPlane: rotatedPlaneAtPoint) ?? camForwardPoint
        let verticalOffset = arView.cameraTransform.matrix.upVector * offsetFromCamera.y
        let horizontalOffset = arView.cameraTransform.matrix.rightVector * offsetFromCamera.x
        return projectionAtRotatedPlane + verticalOffset + horizontalOffset
    }

    func surfaceTransformFromTouchPosition() -> Transform? {
        let pointA = cgPointToWorldspace(previousTouchPosition,
                                         offsetFromCamera: SIMD3<Float>(0, 0, 0.01))
        let pointB = cgPointToWorldspace(previousTouchPosition,
                                         offsetFromCamera: SIMD3<Float>(0, 0, 0.02))
        let query = ARRaycastQuery(origin: pointA,
                                   direction: normalize(pointB - pointA),
                                   allowing: .estimatedPlane,
                                   alignment: .any)
        guard let hit = arView.session.raycast(query).first else { return nil }
        return Transform(matrix: hit.worldTransform)
    }

    func checkForTractorBeam(_ touchPoint: CGPoint) {
        // Tractor beam performs no action if you are already carrying a creature
        if carriedCreature == nil {
            // Grab a creature if there is one
            if let targetCreatureEntity = getTractorBeamableCreature(touchPoint) as? CreatureEntity {
                if targetCreatureEntity.isTractorBeamable() {
                    targetCreatureEntity.activateTractorBeam()
                    inputSystemDelegate?.playerAchievedTractorBeam()
                    carriedCreature = targetCreatureEntity
                }
            }
        }
    }

    func checkForWhack() {
        // If you're already carrying a creature around with the tractor beam,
        // we don't want to bother processing Whack input.
        if carriedCreature != nil { return }

        // Has enough time passed since the last whack?
        if Date().timeIntervalSince1970.magnitude - whackTime > whackTimeout {
            if let data = motion.accelerometerData {
                var currentZAcceleration = data.acceleration.z
                let accelerationChange = currentZAcceleration - previousZAcceleration
                if accelerationChange < -Double(Options.whackAccelerationThreshold.value) {
                    whackTime = Date().timeIntervalSince1970.magnitude
                    // Clear acceleration for next time
                    currentZAcceleration = 0
                    // Perform Whack action and destroy Target Creature
                    inputSystemDelegate?.playerAchievedWhack()
                }
                previousZAcceleration = currentZAcceleration
            }
        }
    }

    func getTractorBeamableCreature(_ touchPoint: CGPoint) -> Entity? {
        let hits = arView.hitTest(touchPoint, query: .all, mask: .all)
        for index in 0..<hits.count where hits[index].entity.name == Constants.creatureRcName {
            return hits[index].entity
        }
        return nil
    }
}
