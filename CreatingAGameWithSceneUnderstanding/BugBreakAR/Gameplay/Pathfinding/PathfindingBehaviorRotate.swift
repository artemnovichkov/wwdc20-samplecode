/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Pathfinding Behavior Rotate
*/

import RealityKit
import ARKit
import Combine

class PathfindingBehaviorRotate: PathfindingBehavior {

    override init(creature: CreatureEntity) {
        super.init(creature: creature)
        self.behaviorType = BehaviorType.rotate

        // Ensure a meaningful behavior
        let rotationSpeed = creature.radiansPerSecond()
        if rotationSpeed <= 0 {
            cancel()
            return
        }

        // Add callbacks saying, "Listen for any animation to complete;
        // upon completion, go to the .end state!"
        addAnimationCallbacks(pathfindingComponent.yawEntity)

        // Prepare an angle to animate a rotation
        let angle = Float.random(in: -Float.pi / 2...Float.pi / 2)

        // Prepare the animation
        let transform = Transform(pitch: 0, yaw: angle, roll: 0)
        let duration = abs(angle) / rotationSpeed
        pathfindingComponent.yawEntity.move(to: transform,
                                                relativeTo: pathfindingComponent.yawEntity.parent,
                                                duration: Double(duration))

        // Set the state for the update loop to begin animating
        behaviorState = .midAction
    }
}
