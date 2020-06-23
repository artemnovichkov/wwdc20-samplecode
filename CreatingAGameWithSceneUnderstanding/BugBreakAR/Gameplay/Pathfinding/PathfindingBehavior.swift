/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Pathfinding Behavior
*/

import ARKit
import RealityKit
import Combine

public class PathfindingBehavior {

    public enum BehaviorType: CaseIterable {
        case crawl
        case hop
        case idle
        case rotate
        case turnaway
    }

    public enum BehaviorState {
        case begin
        case midAction
        case midAlternateAction
        case end
    }

    public var behaviorType: BehaviorType!
    public var behaviorState = BehaviorState.begin
    public var requiresTrail: Bool = true

    public var creature: CreatureEntity
    public var pathfindingComponent: PathfindingComponent
    public var arView: ARView!

    public var nextTarget: Transform?
    public var maxTargetDistanceAllowed: Float = 0
    public var minTargetDistanceAllowed: Float = 0

    public var hasAnimationCallback = false
    public var animationPlaybackSubscriptions = [AnyCancellable]()

    // If we try to find a target and miss, rotate by 45 degress in
    // an assigned direction
    var assignedTurnDirection: Float = 1
    // The number of times player is allowed to try to find a Target and miss
    var raycastMissCount = 0
    // Each time player misses, increment rotation by 45 degrees.
    // 8 increments is a full circle, so 7 (8-1) is our maximum count:
    var maxRaycastMissCount = 7

    init(creature: CreatureEntity) {
        self.creature = creature
        self.pathfindingComponent = creature.pathfinding
        self.arView = creature.arView
    }

    public func updateWithSuccess(_ deltaTime: Float) -> Bool {
        if behaviorState == .end {
            cancel()
            return false
        }
        return true
    }

    public func addAnimationCallbacks(_ animatingEntity: Entity) {
        if hasAnimationCallback { return }
        hasAnimationCallback = true
        guard let arView = creature.arView else { return }
        arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self,
                                        on: animatingEntity).sink { [weak self] _ in
                                            self?.cancel()
        }.store(in: &animationPlaybackSubscriptions)
    }

    public func cancel() {
        behaviorState = .end
        for sub in animationPlaybackSubscriptions {
            sub.cancel()
        }
        animationPlaybackSubscriptions.removeAll()
        hasAnimationCallback = false
    }

    /// Point of insertion for the user to suggest a pathfinding target other than the calculated one
    public func suggestPathfindingTarget(_ point: SIMD3<Float>) -> Bool {
        if behaviorState == .midAction {
            let localPoint = pathfindingComponent.yawEntity.convert(position: point, from: nil)
            setLocalPathfindingTarget(localPoint)
            return true
        }
        return false
    }

    /// Sets the pathfinding target. Position vector should be local to the creature's position.
    /// Orients the Creature towards the new target.
    public func setLocalPathfindingTarget(_ pointProjectedOntoXZPlane: SIMD3<Float>) {
        // Sanity check
        let turnSpeed = creature.radiansPerSecond()
        if turnSpeed <= 0 {
            return
        }
        // Indicate that we are in the middle of a new action, apart from the
        // main behavior
        behaviorState = .midAlternateAction
        // Set up the rotation required to look at the new target
        let angle = atan2f(pointProjectedOntoXZPlane.x, pointProjectedOntoXZPlane.z)
        let targetRotationTransform = Transform(pitch: 0, yaw: angle, roll: 0)
        let duration = abs(angle) / turnSpeed
        // Animate the rotation by lerping between two transforms over time
        // We call `move(to:relativeTo:duration:)` so that animation callbacks
        // fire
        pathfindingComponent.yawEntity.move(to: targetRotationTransform,
                                       relativeTo: pathfindingComponent.yawEntity,
                                       duration: Double(duration))

        if !hasAnimationCallback {
            hasAnimationCallback = true
            // Set up the animation callback which tells the path finding behavior
            // to go back to its "begin" state when animation is complete.
            pathfindingComponent.scene?.publisher(for: AnimationEvents.PlaybackCompleted.self,
                                             on: pathfindingComponent.yawEntity).sink { [weak self] _ in
                                                self?.behaviorState = .begin
            }
            .store(in: &animationPlaybackSubscriptions)
        }
        // Update debug visualizations
        pathfindingComponent.targetVizModel?.position =
            pathfindingComponent.yawEntity.convert(position: pointProjectedOntoXZPlane, to: nil)
    }

    /// Determines if the target is nil, too short or too far
    func isInvalidTarget(_ target: Transform?) -> Bool {
        guard let target = target else { return true }
        let hitDistance = length(target.translation -
            pathfindingComponent.yawEntity.position(relativeTo: nil))
        let isTooClose = hitDistance < minTargetDistanceAllowed
        let isTooFar = hitDistance > maxTargetDistanceAllowed
        return isTooClose || isTooFar
    }

    func adjustPathfindingTarget() {
        // Rotate incrementally in the assigned direction
        let localTargetPoint = SIMD3<Float>(1, 0, assignedTurnDirection)
        setLocalPathfindingTarget(localTargetPoint)
        // Keep track of how many times we do this, so that we don't end up spinning in circles
        raycastMissCount += 1
    }

    func performRaycast(origin: SIMD3<Float>, direction: SIMD3<Float>) -> Transform? {
        // Make the raycast query
        let query = ARRaycastQuery(origin: origin,
                                   direction: normalize(direction),
                                   allowing: .estimatedPlane,
                                   alignment: .any)
        // Note: Ray-casting is the preferred method for finding positions on surfaces
        //       *in the real-world environment*.
        // This is why we don't have to use layers or filter out our Game Assets
        guard let hit = arView.session.raycast(query).first else { return nil }

        // Update debug visualizations
        pathfindingComponent.raycastVizModel?.setTransformMatrix(hit.worldTransform,
                                                            relativeTo: nil)

        // Not all mesh faces are wound in the same direction. For this reason, we encounter an
        // occasional inverted normal. Also, if we raycast through a hole in the mesh,
        // we may hit the backface of some unintended surface. For this reason, we check the normal here.
        let targetTransform = Transform(matrix: hit.worldTransform)
        let targetNormal = targetTransform.matrix.upVector
        let creatureNormal = pathfindingComponent.normalPlaneEntity.transformMatrix(relativeTo: nil).upVector
        let dotProduct = dot(targetNormal, creatureNormal)
        if dotProduct >= 0 {
            return targetTransform
        }
        return nil
    }

    static func generateBehavior(for type: BehaviorType, with creature: CreatureEntity) -> PathfindingBehavior {
        switch type {
        case .crawl: return PathfindingBehaviorCrawl(creature: creature)
        case .hop: return PathfindingBehaviorHop(creature: creature,
                                                 debugAnchorEntity: creature.pathfinding.parabolaEntity)
        case .idle: return PathfindingBehaviorIdle(creature: creature)
        case .rotate: return PathfindingBehaviorRotate(creature: creature)
        case .turnaway: return PathfindingBehaviorTurnAwayFromPlayer(creature: creature)
        }
    }

    static var anyLegalBehaviorType: BehaviorType {
        let randomizedTypes = BehaviorType.allCases.shuffled()
        for index in 0..<randomizedTypes.count {
            if isLegalBehaviorType(randomizedTypes[index]) {
                return randomizedTypes[index]
            }
        }

        return .idle
    }

    static func isLegalBehaviorType(_ behaviorType: BehaviorType) -> Bool {
        switch behaviorType {
        case .crawl:
            return Options.isCrawlLegal.value
        case .hop:
            return Options.isHopLegal.value
        case .idle:
            return Options.isIdleLegal.value
        case.rotate:
            return Options.isRotateLegal.value
        case.turnaway:
            return true
        }
    }

    deinit {
        animationPlaybackSubscriptions = []
    }
}
