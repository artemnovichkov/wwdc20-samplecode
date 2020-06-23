/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Creature Entity Pathfinding
*/

import Foundation
import RealityKit

extension CreatureEntity: HasPathfinding, PathfindingComponentDelegate {
    internal func configurePathfinding() {
        pathfinding = PathfindingComponent()
        pathfinding.gameManager = gameManager
        pathfinding.scene = gameManager?.viewController?.arView.scene
        pathfinding.entity = self
        pathfinding.delegate = self
    }

    public func behaviorChanged(_ behavior: PathfindingBehavior.BehaviorType) {
        // Update the Creature's USDZ animation state based on the desired behavior
        switch behavior {
        case .idle:
            let idleAnimState = Options.calmIdleAnimation.value ? AnimationState.calmIdling : AnimationState.idling
            setAnimation(animation: idleAnimState)
            playSound(name: Constants.idleAudioName)
        case .crawl:
            setAnimation(animation: .walking)
            playSound(name: Constants.walkAudioName)
        default:
            setAnimation(animation: .fluttering)
            playSound(name: Constants.flutterAudioName)
        }
    }
}
