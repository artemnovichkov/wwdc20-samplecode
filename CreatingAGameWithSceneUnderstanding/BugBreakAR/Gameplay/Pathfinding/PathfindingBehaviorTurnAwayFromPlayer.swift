/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Pathfinding Behavior Turn Away From Player
*/

import RealityKit
import ARKit
import Combine

class PathfindingBehaviorTurnAwayFromPlayer: PathfindingBehavior {

    override init(creature: CreatureEntity) {
        super.init(creature: creature)
        self.behaviorType = BehaviorType.turnaway

        // Sanity-check
        let rotationSpeed = creature.radiansPerSecond()
        if rotationSpeed <= 0 {
            cancel()
            return
        }

        // Where is the creature now?
        let creaturePosition = pathfindingComponent.positionEntity.position(relativeTo: nil)

        // Where should the creature be looking?
        let vectorFromUserDevice = creaturePosition - arView.cameraTransform.translation
        let desiredLookAtPoint = creaturePosition + vectorFromUserDevice

        // Add callbacks saying, "Listen for any animation to complete;
        // upon completion, go to the .end state!"
        addAnimationCallbacks(pathfindingComponent.yawEntity)

        // Calculate yaw by projecting the desired Look-at point onto the XZ plane
        let pointProjectedOntoXZPlane =
            pathfindingComponent.normalPlaneEntity.convert(position: desiredLookAtPoint,
                                                               from: nil)
        // Top-down View of Projected XZ Plane
        // Note that what is usually the Y axis is now the -Z axis.
        //
        // We are calculating an offset/difference angle here, so imagine that
        // our Creature (who is looking along the +Z axis by default) currently
        // has a no rotation. Its current Look-at target (A) is simply
        // the positive Z axis.
        //
        //                     -Z     * <-- (Player Position)
        //                        |  /
        //                       .|./               .'.
        //                      ( | )              (   )
        //              -X ____(__|__)____ X      (     ) <-- (That is meant
        //                      (@|@)              (@ @)       to be the Creature
        //                     /  |                            from the Top View
        //                    / t |                            on the Axis plane.)
        // (New Look-at ---> B    A <-- (Current Look-at Point,
        //     Point)                     aka the +Z axis)
        //
        // We want it to have a new rotation (t) whereby its Forward Vector
        // is pointing at the desired Look-at Point (B).
        //
        // Thanks to our XZ Plane, this is easy, because we have the X coordinate
        // and the Z coordinate, and can just take the arctangent to get the angle (t).
        //
        let angle = atan2f(pointProjectedOntoXZPlane.x, pointProjectedOntoXZPlane.z)
        // Build the Rotation animation
        let transform = Transform(pitch: 0, yaw: angle, roll: 0)
        let duration = abs(angle) / rotationSpeed
        pathfindingComponent.yawEntity.move(to: transform,
                                                relativeTo: pathfindingComponent.normalPlaneEntity,
                                                duration: Double(duration))
        behaviorState = .midAction
    }
}
