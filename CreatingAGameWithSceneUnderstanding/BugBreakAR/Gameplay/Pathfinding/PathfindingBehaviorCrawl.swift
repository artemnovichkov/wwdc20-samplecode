/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Pathfinding Behavior Crawl
*/

import Foundation
import os.log
import RealityKit

class PathfindingBehaviorCrawl: PathfindingBehavior {

    let log = OSLog(subsystem: appSubsystem, category: "PathfindingBehaviorCrawl")

    var crawlStartTime: Double = Date().timeIntervalSinceReferenceDate
    var crawlTimeLimitLower: Double = 3
    var crawlTimeLimitUpper: Double = 8
    let forwardRaycastLength: Float = Constants.creatureShape.z / 2
    var avoidancePoints = [Transform]()
    var gameManager: GameManager?

    // Offset used when raycasting to diminish
    // chances of raycasting directly onto a surface normal.
    let slightOffset: Float = 0.001

    override init(creature: CreatureEntity) {
        self.gameManager = creature.gameManager
        super.init(creature: creature)
        // Let's say we don't want to exceed 95% of the creature length
        self.maxTargetDistanceAllowed = Constants.creatureShape.z * 0.95
        self.behaviorType = BehaviorType.crawl
        // Creature will always turn in this direction until behavior is destroyed.
        // Creatures with an odd birthday turn left, evens turn right.
        if Int(creature.birthday) % 2 == 0 {
            assignedTurnDirection *= -1
        }
    }

    public override func updateWithSuccess(_ deltaTime: Float) -> Bool {
        if behaviorState == .end {
            // Reached the end?
            cancel()
            return false
        } else if Date().timeIntervalSinceReferenceDate - crawlStartTime >
                    Double.random(in: crawlTimeLimitLower...crawlTimeLimitUpper) {
            // Too long?
            cancel()
            log.debug("Reached crawl time limit!")
            return false
        } else if raycastMissCount > maxRaycastMissCount {
            // Too futile?
            return false
        } else if behaviorState == .midAlternateAction {
            // In the middle of turning? Don't try to move forward
            return true
        } else {
            // Proceed with Crawl
            return crawlWithSuccess(deltaTime: deltaTime)
        }
    }

    func crawlWithSuccess(deltaTime: Float) -> Bool {
        // Keep our legality up to date
        updateAvoidancePoints()
        // Look ahead for an orthogonal surface
        nextTarget = intersectStraightForward()
        // Look ahead for more coplanar surface
        if isInvalidTarget(nextTarget) {
            nextTarget = intersectStraightDownFromFront()
        }
        if isInvalidTarget(nextTarget) {
            // Failed. Check my normals
            return reorientToSurfaceAndAdjustWithSuccess()
        }
        // Success: Crawl
        behaviorState = .midAction
        return crawlTowardsTransformWithSuccess(targetTransform: nextTarget,
                                                deltaTime: deltaTime)
    }

    /// Verifies that the creature is correctly aligned with surface normal,
    /// and then rotates to refresh raycast options.
    func reorientToSurfaceAndAdjustWithSuccess() -> Bool {
        nextTarget = intersectStraightDownFromCenter()
        // Check if the target is too far or nonexistent
        if isInvalidTarget(nextTarget) {
            // The mesh you were standing on disappeared, OR, you are on the flip side of a normal,
            // and the raycast cannot pick up the backface you're currently standing on.
            cancel()
            return false
        }
        adjustPathfindingTarget()
        return true
    }

    /// Checks for other creatures we may encounter
    func updateAvoidancePoints() {
        avoidancePoints.removeAll()
        if let otherCreatures = gameManager?.creatureEntities {
            for index in 0..<otherCreatures.count where otherCreatures[index] != creature {
                avoidancePoints.append(otherCreatures[index].transform)
            }
        }
    }

    /// Check for conflict with avoidance point
    func conflictsWithAvoidancePoint(_ target: Transform) -> Bool {
        for index in 0..<avoidancePoints.count {
            // Heading towards it?
            if dot(avoidancePoints[index].matrix.forwardVector,
                   pathfindingComponent.yawEntity.transform.matrix.forwardVector) <= 0 {
                // Close enough to me?
                let distanceToPoint = distance(avoidancePoints[index].translation,
                                               pathfindingComponent.positionEntity.position(relativeTo: nil))
                if distanceToPoint <= forwardRaycastLength {
                    // Avoid thing
                    return true
                }
            }
        }
        return false
    }

    /// Incrementally move creature position towards target, incrementally align creature rotation with target
    func crawlTowardsTransformWithSuccess(targetTransform: Transform?,
                                          deltaTime: Float) -> Bool {
        // Sanity check
        guard let targetTransform = targetTransform else { return false }
        // Make sure the target is still legal
        if conflictsWithAvoidancePoint(targetTransform) {
            turnLeft()
            return true
        }
        // Calculate the offset we need to append to our current position to
        // crawl at a specific speed in a specific direction
        let crawlDistance = creature.getCreatureSpeed() * deltaTime
        let crawDirection = targetTransform.translation -
            pathfindingComponent.positionEntity.position(relativeTo: nil)
        let positionOffset = normalize(crawDirection) * crawlDistance

        // Update our position according to these calculations
        let newPosition = pathfindingComponent.positionEntity.position(relativeTo: nil) + positionOffset
        pathfindingComponent.positionEntity.setPosition(newPosition, relativeTo: nil)

        // Derive a quaternion describing the rotation offset of the hit normal
        let normalRotation = simd_quatf(from: SIMD3<Float>(0, 1, 0),
                                        to: targetTransform.matrix.upVector)
        // Check for Nans, the simd_quatf from/to function is hairy about
        // rotations from 0,1,0 to 0,-1,0
        if !normalRotation.real.isNaN {
            // Calculate how far we are allowed to legally travel
            let distanceRemaining = distance(targetTransform.translation,
                                             newPosition)
            if distanceRemaining > 0 {
                let progress = crawlDistance / distanceRemaining
                pathfindingComponent.normalPlaneEntity.transform.rotation =
                    simd_slerp(pathfindingComponent.normalPlaneEntity.transform.rotation,
                               normalRotation,
                               progress)
            } else {
                pathfindingComponent.normalPlaneEntity.transform.rotation = normalRotation
            }
        }
        // Reset our miss counter
        raycastMissCount = 0
        return true
    }

    func turnLeft() {
        let localTargetPoint = SIMD3<Float>(1, 0, 0)
        setLocalPathfindingTarget(localTargetPoint)
        raycastMissCount += 1
    }

    // Coplanar surface ahead
    public func intersectStraightDownFromFront() -> Transform? {
        // Get Creature forward Vector in world space
        let creatureFront = SIMD3<Float>(0,
                                         Constants.creatureShape.y / 2,
                                         forwardRaycastLength)
        let creatureFrontWorld = pathfindingComponent.yawEntity.convert(position: creatureFront,
                                                                   to: nil)
        let localDir = SIMD3<Float>(0, -1, slightOffset)
        let creatureDownWorld = pathfindingComponent.yawEntity.convert(direction: localDir,
                                                                  to: nil)
        return performRaycast(origin: creatureFrontWorld,
                              direction: creatureDownWorld)
    }

    // Orthogonal surface ahead
    public func intersectStraightForward() -> Transform? {
        // Get position of creature's nose
        let creatureFront = SIMD3<Float>(0,
                                         Constants.creatureShape.y / 2,
                                         forwardRaycastLength)
        let creatureFrontWorld = pathfindingComponent.yawEntity.convert(position: creatureFront,
                                                                   to: nil)
        // Get creature forward Vector in world space
        let localDir = SIMD3<Float>(0, slightOffset, 1)
        let creatureForwardWorld = pathfindingComponent.yawEntity.convert(direction: localDir,
                                                                     to: nil)
        return performRaycast(origin: creatureFrontWorld,
                              direction: creatureForwardWorld)
    }

    // Surface directly beneath
    public func intersectStraightDownFromCenter() -> Transform? {
        let modelCenterLocal = SIMD3<Float>(0, Constants.creatureShape.y / 2, 0)
        let modelCenterWorld = pathfindingComponent.yawEntity.convert(position: modelCenterLocal,
                                                                          to: nil)
        let localDir = SIMD3<Float>(0, -1, slightOffset)
        let modelDownWorld = pathfindingComponent.yawEntity.convert(direction: localDir,
                                                                        to: nil)
        return performRaycast(origin: modelCenterWorld,
                              direction: modelDownWorld)
    }
}
