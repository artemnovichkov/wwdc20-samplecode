/*
See LICENSE folder for this sample’s licensing information.

Abstract:
EntitySwitcherComponent - allows an Entity to have multiple Entity Children
 and show only one, while hiding the others.  This supports animation on the
 children as well.
*/

import Foundation
import os.log
import RealityKit
import Combine

private let log = OSLog(subsystem: appSubsystem, category: "EntitySwitchComponent")

/// Animation types for `EntitySwitcher`
public enum EntitySwitcherAnimationType {
    case staticModel
    case oneShotAnimation
    case loopingAnimation
}

/// Allows the caller to enable all children with the same name while disabling all of the other
/// children with names in the given list.  This prevents other children not in the allow list from being affected.
/// `EntitySwitcherComponent` keeps track of the name of the currently enabled `Entity`. This may be
/// used for the state transitions of an `Entity` where any number of model or animation entities are
/// children and only one of those children, based on the parent Entity state, should be enabled
/// ( i.e. lit or unlit, walking or jumping, etc.). Physics and collision should be on the parent entity so that
/// when swaps occur, it doesn't cause unexpected behavior in the physics simulation.
public struct EntitySwitcherComponent: Component {

    struct ChildEntityInfo {
        let name: String
        let type: EntitySwitcherAnimationType
        public init(name: String, type: EntitySwitcherAnimationType) {
            self.name = name
            self.type = type
        }
    }

    // configuration
    public var animated = true
    public var scene: Scene?
    public weak var delegate: EntitySwitcherComponentDelegate?

    fileprivate var playbackCompletedSubscriptions = [AnyCancellable]()
    fileprivate var childEntityInfoList = [ChildEntityInfo]()
    fileprivate var childEntities = [String: Entity]()
    fileprivate weak var currentChildEntity: Entity?

    public var infoListNames: String {
        childEntityInfoList.map { $0.name }.joined(separator: "-")
    }

    // allows this struct to be used in a framework
    public init() {}
}

// This Component does not need to be Codable because the host takes care of switching
// child Entities, and my stop/start animations, but those actions
// are automatically networked through the Entities. Nonowners
// (Network clients) of Entities with this Component do not need this
// Component's data transported across the network

public protocol HasEntitySwitcher where Self: Entity {}

public protocol EntitySwitcherComponentDelegate: AnyObject {
    func animationCompleted()
}

extension HasEntitySwitcher where Self: Entity {

    public var entitySwitcher: EntitySwitcherComponent {
        get { return components[EntitySwitcherComponent.self] ?? EntitySwitcherComponent() }
        set { components[EntitySwitcherComponent.self] = newValue }
    }

    public func addChildEntity(_ entity: Entity?, name: String?, type: EntitySwitcherAnimationType) {
        guard let entity = entity else {
            log.error("addChildEntity() called with nil Entity")
            return
        }
        guard let name = name else {
            log.error("addChildEntity() called with nil name")
            return
        }
        guard !entitySwitcher.childEntities.keys.contains(name) else {
            log.error("addChildEntity() called with same name '%s'", "\(name)")
            return
        }

        entitySwitcher.childEntityInfoList.append(EntitySwitcherComponent.ChildEntityInfo(name: name, type: type))
        entity.isEnabled = false
        entitySwitcher.childEntities[name] = entity
        addChild(entity)
    }

    private func fixChild(_ entity: Entity, from: HasEntitySwitcher) {
        let key = entity.name
        // if the entity parent is the previous parent,
        // then this entity reference was not copied
        // which is not expected
        guard entity.parent == from else {
            log.error("didClone(%s) found a child entity with a parent that was not the source of the clone",
                      "\(from.name)")
            return
        }

        // search for a child of parent that matches my name
        let newChild: Entity
        if let child = children.first(where: { $0.name == key }) {
            newChild = child
        } else {
            newChild = entity.clone(recursive: true)
            assert(newChild.parent == nil)
        }

        entitySwitcher.childEntities[key] = newChild
    }

    /// Must be called when the owning `Entity` is cloned to fixup the child `Entity` references
    public func didClone(_ from: HasEntitySwitcher) {
        // the childEntities dictionary was copied from
        // the original Entity during the clone process,
        // so all of the entity references are to the
        // original children and must be cloned if not
        // a current child (which was cloned automatically).
        // For the current child, we need to update the entry
        // in the childEntities dictionary
        entitySwitcher.childEntities
            .map { $0.value }
            .forEach { entity in
                fixChild(entity, from: from)
            }
    }

    public func forEach(_ closure: (Entity) -> Void) {
        entitySwitcher.childEntities.values.forEach {
            closure($0)
        }
    }

    private func registerCompletion(_ animEntity: Entity, animType: EntitySwitcherAnimationType) {
        if animType == .oneShotAnimation {
            scene?.publisher(for: AnimationEvents.PlaybackCompleted.self, on: animEntity)
                .sink { [weak self] _ in
                    self?.entitySwitcher.delegate?.animationCompleted()
                }
                .store(in: &entitySwitcher.playbackCompletedSubscriptions)
        }
    }

    private func activateEntity(_ entity: Entity, as animationType: EntitySwitcherAnimationType) {
        entity.isEnabled = true

        defer {
            entitySwitcher.currentChildEntity = entity
        }
        guard entitySwitcher.animated else { return }

        var animationResource: AnimationResource?
        var paused = false
        if !entity.availableAnimations.isEmpty {
            switch animationType {
            case .staticModel:
                // if there is an animation, play the first frame
                animationResource = entity.availableAnimations[0]
                paused = true
            case .oneShotAnimation:
                animationResource = entity.availableAnimations[0]
            case .loopingAnimation:
                animationResource = entity.availableAnimations[0].repeat()
            }
        } else {
            log.error("'%s' activateEntity(%s) not available",
                      "\(self.name)",
                      "\(entity.name)")
        }

        guard let resource = animationResource else { return }
        let animation = entity.playAnimation(resource, transitionDuration: 0.0, startsPaused: paused)
        guard let animationEntity = animation.entity else { return }

        registerCompletion(animationEntity, animType: animationType)
    }

    private func deactivateEntity(_ entity: Entity) {
        entity.isEnabled = false
    }

    // returns true if the enableNewAnimation call should be made after returning
    private func switchAnimation(from oldEntity: Entity?, to newEntity: Entity?,
                                 animationType newAnimationType: EntitySwitcherAnimationType) {
        // disable old animation
        if let oldEntity = oldEntity {
            // to be considered for disabling, child must be in allow list
            guard entitySwitcher.childEntityInfoList.contains(where: { $0.name == oldEntity.name }) else { return }

            if oldEntity != newEntity, oldEntity.isEnabled {
                if entitySwitcher.animated {
                    oldEntity.stopAllAnimations(recursive: false)
                }
                deactivateEntity(oldEntity)
            }
        }
        if let entity = newEntity {
            activateEntity(entity, as: newAnimationType)
        }
    }

    /// Called to request a state chang. If the requested state is the same as the current state, or
    /// if the specified name is not found, returns without doing anything.
    public func enableChildNamed(_ name: String?) {
        guard !entitySwitcher.childEntityInfoList.isEmpty else {
            fatalError("EntitySwitcherComponent not 'configure'd.")
        }

        // must be a nil request or exist in allow list to act
        let newChildEntityInfo = entitySwitcher.childEntityInfoList.first(where: { $0.name == name })
        guard name == nil || newChildEntityInfo != nil else {
            log.error("'%s' enableChildNamed(%s) was not in allow list '%s'",
                      "\(self.name)", "\(name!)",
                      "\(entitySwitcher.infoListNames)")
            return
        }

        let oldChildEntity = entitySwitcher.currentChildEntity
        if let newChildEntityInfo = newChildEntityInfo, let oldChildEntity = oldChildEntity {
            // don't restart same animation
            guard newChildEntityInfo.name != oldChildEntity.name else {
                return
            }
        }

        // allow a nil name to obtain a nil entity for the switch target
        // either the name should be nil, or if not, then the entity should be non-nil
        let newChildEntity = name != nil ? entitySwitcher.childEntities[name!] : nil
        guard name == nil || newChildEntity != nil else {
            log.error("'%s' enableChildNamed(%s) was not in childEntities '%s'",
                      "\(self.name)", "\(name!)",
                      "\(entitySwitcher.childEntities.keys)")
            return
        }

        let animationType = newChildEntityInfo?.type ?? .staticModel
        switchAnimation(from: oldChildEntity, to: newChildEntity, animationType: animationType)
    }

    public func shutdownEntitySwitcher() {
        entitySwitcher.delegate = nil
        entitySwitcher.playbackCompletedSubscriptions = []
    }

}
