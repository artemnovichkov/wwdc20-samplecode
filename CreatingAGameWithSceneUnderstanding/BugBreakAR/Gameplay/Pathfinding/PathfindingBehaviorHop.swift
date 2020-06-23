/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Pathfinding Behavior Hop
*/

import RealityKit
import ARKit
import Combine

// Hop onto a surface that is ahead and above you
// Hop onto a surface that is ahead and below you
class PathfindingBehaviorHop: PathfindingBehavior {

    let hopRaycastForwardOffset: Float = 0.75
    let hopRaycastUpwardOffset: Float = 0.75
    let minHopDistanceRequired: Float = 0.75
    let maxHopDistanceAllowed: Float = 1.75
    let clearanceThreshold: Float = 0.01

    var hopStartPos: SIMD3<Float>!
    var hopStartRot: simd_quatf!
    var hopStartNormal: SIMD3<Float>!
    var hopStartTime: Double!
    var hopFinishPos: SIMD3<Float>!
    var hopFinishPosLocal: SIMD3<Float>!
    var hopFinishRot: simd_quatf!
    var hopFinishNormal: SIMD3<Float>!
    var hopDuration: Float!
    var normalRotAtFinish: simd_quatf!
    let hopSpeedScalar: Float = 1.75 // m/s

    // At what progress do we consider ourselves to be taking off or landing?
    // Note: Using 0 and 1 for takeoff and landing respectively will introduce
    //  divide-by-zero errors.
    let progressAfterTakeoff: Float = 0.333
    let progressAtLandingTime: Float = 0.666

    // Debug visualizations
    var debugAnchorEntity: Entity?
    var debugSegments = [Entity]()
    let debugSegmentCount = 16
    var debugNormals = [Entity]()

    init(creature: CreatureEntity, debugAnchorEntity: AnchorEntity?) {
        // Init parent class
        super.init(creature: creature)
        self.behaviorType = BehaviorType.hop
        self.requiresTrail = false
        self.minTargetDistanceAllowed = minHopDistanceRequired
        self.maxTargetDistanceAllowed = maxHopDistanceAllowed
        self.debugAnchorEntity = debugAnchorEntity
    }

    public override func updateWithSuccess(_ deltaTime: Float) -> Bool {
        if behaviorState == .end {
            // Your behavior has terminated
            cancel()
            return false
        } else if raycastMissCount > maxRaycastMissCount {
            // Your attempts were futile
            cancel()
            return false
        } else if behaviorState == .midAlternateAction {
            // You're in the middle of turning
            return true
        } else if behaviorState == .midAction {
            // You're in the middle of hopping
            return updateHopWithSuccess()
        } else {
            // You're in the .begin state, and trying to find
            // a target.
            // Can we hop "down" onto a surface?
            nextTarget = intersectStraightDownFromForwardAndUpward()
            // isInvalidTarget checks for nil
            if isInvalidTarget(nextTarget) || !hasClearance(nextTarget!) {
                // Unsuccessful case: Rotate a bit using the .midAlternateAction state,
                // and start over.
                adjustPathfindingTarget()
                return true
            } else {
                // Hop there, beginning the .midAction state
                initializeHop(nextTarget!) // If statement checked for nil already
                return true
            }
        }
    }

    // Check the Creature's "gaze". If it can see the target, there will likely be
    // no collisions on the way there.
    func hasClearance(_ targetTransform: Transform) -> Bool {
        // Approximate position of creature's head
        let creatrueHead = SIMD3<Float>(0,
                                        Constants.creatureShape.y / 2,
                                        Constants.creatureShape.z / 2)
        let origin = pathfindingComponent.yawEntity.convert(position: creatrueHead,
                                                                to: nil)
        let direction = targetTransform.translation - origin
        if let hitTransform = performRaycast(origin: origin, direction: direction) {
            let collisionDistance = distance(hitTransform.translation, origin)
            let hopDistance = distance(targetTransform.translation, origin)
            return (hopDistance - collisionDistance) <= clearanceThreshold
        }
        // This should never happen
        return true
    }

    func initializeHop(_ hitTransform: Transform) {
        // Verify we're going somewhere
        let hopSpeed = hopSpeedScalar * creature.getCreatureSpeed()
        if hopSpeed <= 0 {
            cancel()
            return
        }
        // Initialize some data about the hop
        hopStartPos = pathfindingComponent.yawEntity.position(relativeTo: nil)
        hopStartRot = pathfindingComponent.yawEntity.orientation(relativeTo: nil)
        hopStartNormal = pathfindingComponent.yawEntity.convert(direction: SIMD3<Float>(0, 1, 0), to: nil)
        hopFinishPos = hitTransform.translation
        hopFinishRot = hitTransform.rotation
        hopFinishNormal = hitTransform.matrix.upVector
        // By utilizing local space, we can confine the parabola to 2 axes, making
        // the math much simpler.
        hopFinishPosLocal = pathfindingComponent.yawEntity.convert(position: hopFinishPos,
                                                                       from: nil)
        // Calculate hop duration
        let hopDistance = distance(hopStartPos,
                                        hopFinishPos)
        hopDuration = hopDistance / hopSpeed
        hopStartTime = Date().timeIntervalSinceReferenceDate

        // We need to rotate to face the new normal as well
        normalRotAtFinish = simd_quatf(from: SIMD3<Float>(0, 1, 0),
                                       to: hitTransform.matrix.upVector)
        if normalRotAtFinish.real.isNaN {
            normalRotAtFinish = simd_quatf.identity
        }

        // Turn on some visualizations if you'd like
        pathfindingComponent.targetVizModel?.setPosition(hitTransform.translation, relativeTo: nil)
        if Options.debugPathfinding.value {
            visualizeParabola(targetPosLocal: hopFinishPosLocal)
        }

        // Begin
        behaviorState = .midAction
    }

    func updateHopWithSuccess() -> Bool {
        // Sanity check
        guard let nextTarget = nextTarget else { return false }
        // Derive current progress
        let progress = Float(Date().timeIntervalSinceReferenceDate - hopStartTime) / hopDuration
        // If you're still traversing the parabola
        if progress < 1 {
            // To determine the creature's position, we will use a Parabola.
            // Parabolic curve as a function of height: y = ax^2 + bx + c
            //   "c" is an offset from the origin, in our case (local space), 0.
            //   We are traveling within the YZ plane, so our "x" will be our Z value.
            //   We assign "a" based on a function that tells us how steep/flat our parabola should be.
            // Steep/Flatness of a parabola is called "Eccentricity"
            let aVal = getEccentricity(normalAtSource: hopStartNormal, normalAtDest: hopFinishNormal)
            // Rearrange the parabolic curve function to solve for "b"
            let bVal = (hopFinishPosLocal.y - aVal * hopFinishPosLocal.z * hopFinishPosLocal.z)
                / hopFinishPosLocal.z
            // Scale our Z distance by our progress
            let zValue = hopFinishPosLocal.z * progress
            // Now solve the parabolic curve function for "y"
            let yValue = (aVal * zValue * zValue) + (bVal * zValue)
            // We now have our local space offset as derived by the parabolic function
            let parabolicOffset = SIMD3<Float>(0, yValue, zValue)
            // Transform our local offset to world space by appending it to our start position
            // and rotating it by our start rotation.
            let hopCurrPos = hopStartPos + hopStartRot.act(parabolicOffset)
            pathfindingComponent.positionEntity.setPosition(hopCurrPos, relativeTo: nil)

            // We want the creature to rotate like a house fly would. They tend
            // to realign their feet to the ground midflight.
            // But only on some types of flights!
            //
            // Flight paths with a dot product of less than 0:
            // - Flying from ceiling to floor, they DO realign.
            // - Flying from floor to ceiling, they DO realign (although this is often redundant).
            // - Flying from a spot on a wall to an OPPOSING wall, they DO realign.
            // - Flying from a spot on a wall to a spot on an ADJACENT wall, they DO realign... etc
            //
            // Conversely, on flight paths with a dot product of greater than 0:
            // - Flying from a spot on a wall to a spot on the SAME wall, they DO NOT realign.
            // - Flying from ceiling to wall, they DO NOT realign (but they will land along their fwd vector)
            // - Flying from floor to wall, they DO NOT realign (but they will land along their fwd vector)... etc
            if dot(hopStartNormal, hopFinishNormal) < 0 {
                if progress < progressAfterTakeoff {
                    // Take-off!
                    let remappedProgress = progress / progressAfterTakeoff
                    pathfindingComponent.normalPlaneEntity.transform.rotation =
                        simd_slerp(pathfindingComponent.normalPlaneEntity.transform.rotation,
                                   simd_quatf.identity,
                                   remappedProgress)
                } else if progress > progressAtLandingTime {
                    // Landing!
                    var normalRotation = simd_quatf(from: SIMD3<Float>(0, 1, 0),
                                                    to: nextTarget.matrix.upVector)
                    if normalRotation.real.isNaN {
                        // Substituting NaN for Identity per RK bug handling of 180 or 0 degree turns
                        normalRotation = simd_quatf.identity
                    }
                    let remappedProgress = (progress - progressAtLandingTime) / (1 - progressAtLandingTime)
                    pathfindingComponent.normalPlaneEntity.transform.rotation =
                        simd_slerp(pathfindingComponent.normalPlaneEntity.transform.rotation,
                                   normalRotation,
                                   remappedProgress)
                }
            }
            return true
        } else {
            // You're finished with the parabola
            pathfindingComponent.positionEntity.setPosition(hopFinishPos, relativeTo: nil)
            pathfindingComponent.normalPlaneEntity.orientation = normalRotAtFinish
            cancel()
            return false
        }
    }

    // Is there a ledge above us, or a floor beneath us? Ex: from sofa to table, or table to floor
    public func intersectStraightDownFromForwardAndUpward() -> Transform? {
        // We'll raycast from a bit ahead of the creature, so that we can detect
        // a ground surface in front of them
        let localUpForwardOffset = SIMD3<Float>(0,
                                                hopRaycastUpwardOffset,
                                                hopRaycastForwardOffset)
        let origin = pathfindingComponent.yawEntity.convert(position: localUpForwardOffset,
                                                                to: nil)
        // Straight-down seems to trigger a raycasting bug, whereby mesh hits are not detected if you
        // raycast along their normals. For this reason, we'll use a tiny offset in Z.
        let direction = pathfindingComponent.yawEntity.convert(direction: SIMD3<Float>(0, -1, 0.01),
                                                                   to: nil)
        return performRaycast(origin: origin, direction: direction)
    }

    public override func cancel() {
        super.cancel()
        // Clean up visualizations
        if debugSegments.isEmpty {
            for idx in 0..<debugSegments.count {
                debugSegments[idx].removeFromParent()
            }
        }
        if debugNormals.isEmpty {
            for idx in 0..<debugNormals.count {
                debugNormals[idx].removeFromParent()
            }
        }
    }

    func getEccentricity(normalAtSource: SIMD3<Float>, normalAtDest: SIMD3<Float>) -> Float {
        // The more alike the normals are, the more we want a little bounce in our hop shape.
        // The more opposed our normals are, the more we want a straight line.
        var eccentricity = dot(normalAtSource, normalAtDest)
        // However, we also want to dampen the eccentricity if the direction of the hop is With gravity
        let worldDown = SIMD3<Float>(0, -1, 0)
        if dot(hopStartNormal, hopFinishNormal) > 0 && dot(hopStartNormal, worldDown) > 0 {
            eccentricity *= 0.8 // Take about 20% off there, bud!
        }
        // and perhaps exaggerate it if it's going against gravity (think of the force required for you
        // to jump off the ground, vs force required to rappel across a sheer surface)
        if dot(hopStartNormal, hopFinishNormal) > 0 && dot(hopStartNormal, worldDown) < -0.5 {
            eccentricity *= 2 // Add 20% for some flair.
        }
        // Positive eccentricity gives us a concave u-shape
        // Negative eccentricity gives us a convex n-shape
        return -clampValue(eccentricity, 0, 1)
    }

    public func visualizeParabola(targetPosLocal: SIMD3<Float>) {
        // Sanity check
        guard let nextTarget = nextTarget else { return }
        // Generate parabola segments if they do not exist already
        if debugSegments.isEmpty {
            let segmentColor: SimpleMaterial.Color = .white
            for _ in 0..<debugSegmentCount {
                let debugCube = ModelEntity(mesh: MeshResource.generateBox(size: 0.025),
                                            materials: [SimpleMaterial(color: segmentColor, isMetallic: false)])
                let anchorEntity = Entity()
                anchorEntity.addChild(debugCube)
                debugAnchorEntity?.addChild(anchorEntity)
                debugSegments.append(anchorEntity)
            }
        }

        // Position the segments based on the parabolic formula: y = ax^2 + bx + c
        let aVal = getEccentricity(normalAtSource: hopStartNormal,
                                   normalAtDest: hopFinishNormal)
        let bVal = (targetPosLocal.y - aVal * targetPosLocal.z * targetPosLocal.z) / targetPosLocal.z
        for idx in 0..<debugSegmentCount {
            let zValue = (targetPosLocal.z / Float(debugSegmentCount)) * Float(idx) // Progress
            let yValue = (aVal * zValue * zValue) + (bVal * zValue) // Solve for Y
            let pointLocal = SIMD3<Float>(0, yValue, zValue)
            debugSegments[idx].setPosition(pointLocal, relativeTo: pathfindingComponent.yawEntity)
        }

        // Visualize the beginning and ending hit points and their normals
        visualizeEndpoint(position: pathfindingComponent.positionEntity.position(relativeTo: nil),
                          rotation: pathfindingComponent.yawEntity.orientation(relativeTo: nil))

        visualizeEndpoint(position: nextTarget.translation,
                          rotation: nextTarget.rotation)
    }

    func visualizeEndpoint(position: SIMD3<Float>, rotation: simd_quatf) {
        let anchor = Entity()
        anchor.position = position
        anchor.orientation = rotation
        let poseIndicator = ModelEntity(mesh: MeshResource.generateBox(size: SIMD3<Float>(0.01, 0.1, 0.01)),
                                        materials: [SimpleMaterial(color: .green, isMetallic: false)])
        anchor.addChild(poseIndicator)
        let positiveDirectionIndicator = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.01),
                                                     materials: [SimpleMaterial(color: .green, isMetallic: false)])
        poseIndicator.addChild(positiveDirectionIndicator)
        positiveDirectionIndicator.setPosition(SIMD3<Float>(0, 0.05, 0), relativeTo: positiveDirectionIndicator.parent)
        debugAnchorEntity?.addChild(anchor)
        debugNormals.append(anchor)
    }
}
