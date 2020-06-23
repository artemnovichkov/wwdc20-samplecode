/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Pathfinding Behavior Idle
*/

import RealityKit
import ARKit
import Combine

class PathfindingBehaviorIdle: PathfindingBehavior {

    let idleTimeMin: Float = 1
    let idleTimeMax: Float = 2
    var idleDuration: Float!
    var idleTimeCurrent: Float = 0

    override init(creature: CreatureEntity) {
        super.init(creature: creature)
        self.behaviorType = BehaviorType.idle
        self.requiresTrail = false
        idleDuration = Float.random(in: idleTimeMin ... idleTimeMax)
        idleTimeCurrent = 0
        behaviorState = .midAction
    }

    public override func updateWithSuccess(_ deltaTime: Float) -> Bool {
        if behaviorState == .end {
            cancel()
            return false
        }

        idleTimeCurrent += deltaTime
        if idleTimeCurrent < idleDuration {
            return true
        } else {
            cancel()
            return false
        }
    }

    public override func cancel() {
        super.cancel()
    }
}
