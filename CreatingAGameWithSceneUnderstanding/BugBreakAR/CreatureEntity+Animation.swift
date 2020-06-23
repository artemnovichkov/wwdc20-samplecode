/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Creature Entity Animation
*/

import Foundation
import RealityKit

public enum AnimationState: Int {
    case none, entering, idling, calmIdling, walking, fluttering

    static let defaultOption = AnimationState.none
    public var name: String? {
        switch self {
        case .none: return nil
        case .entering: return Constants.creatureEntranceAnimName
        case .idling: return Constants.creatureIdleAnimName
        case .calmIdling: return Constants.creatureCalmIdleAnimName
        case .walking: return Constants.creatureWalkAnimName
        case .fluttering: return Constants.creatureFlutterAnimName
        }
    }

    public var animationType: EntitySwitcherAnimationType {
        switch self {
        case .none: return .staticModel
        case .entering: return .oneShotAnimation
        case .idling: return .loopingAnimation
        case .calmIdling: return .loopingAnimation
        case .walking: return .loopingAnimation
        case .fluttering: return .loopingAnimation
        }
    }

    public var valueString: String { return String(format: "0x%08x", rawValue) }
}

extension CreatureEntity: HasEntitySwitcher, EntitySwitcherComponentDelegate {

    public func configureAnimations(scene: Scene) {
        entitySwitcher = EntitySwitcherComponent()
        // The only way to listen for animation completion events is for the
        // current scene to subscribe to them
        entitySwitcher.scene = scene
        entitySwitcher.delegate = self
        entitySwitcher.animated = true

        addChildEntity(entranceAnim,
                       name: AnimationState.entering.name,
                       type: AnimationState.entering.animationType)
        addChildEntity(idleAnim,
                       name: AnimationState.idling.name,
                       type: AnimationState.idling.animationType)
        addChildEntity(calmIdleAnim,
                       name: AnimationState.calmIdling.name,
                       type: AnimationState.calmIdling.animationType)
        addChildEntity(walkAnim,
                       name: AnimationState.walking.name,
                       type: AnimationState.walking.animationType)
        addChildEntity(flutterAnim,
                       name: AnimationState.fluttering.name,
                       type: AnimationState.fluttering.animationType)
    }

    public func setAnimation(animation: AnimationState) {
        currentAnimationState = animation
        enableChildNamed(animation.name)
    }

    public func animationCompleted() {
        if currentAnimationState == .entering {
            enterAnimationCompleted()
        }
    }

    private func enterAnimationCompleted() {
        // start pathfinding
        pathfinding.delegate = self
        pathfinding.gameManager = gameManager
        pathfinding.entity = self
        if Options.enablePathfinding.value {
            pathfinding.startPathfinding()
            currentState = .pathfinding
        } else {
            currentState = .none
            setAnimation(animation: Options.calmIdleAnimation.value ? .calmIdling : .idling)
        }
    }
}
