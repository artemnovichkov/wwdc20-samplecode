/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Pathfinding Component
*/

import os.log
import RealityKit

private let log = OSLog(subsystem: appSubsystem, category: "PathfindingComponent")

/// The path finding system represents an entity's position and rotation at any given moment.
/// It is implemented as a nested set of transforms. Functions like a tripod in photography.
public struct PathfindingComponent: Component {

    // Tells us only positional data: Its rotation components are never accessed.
    let positionEntity = AnchorEntity()

    // Child of `positionEntity`, this describes only XZ rotation,
    // This identifies the entity's up vector `normalPlaneEntity`'s Y rotation
    // values and positional values are never accessed.
    let normalPlaneEntity = Entity()

    // Child of `normalPlaneEntity`, this describes only Y rotation.
    // This identifies the direction to the entity's forward vector.
    // yawEntity's X and Z rotation values and positional values are never accessed.
    let yawEntity = Entity()

    // Used to anchor models for Debug Visualizations
    var raycastVizEntity: AnchorEntity?
    var targetVizEntity: AnchorEntity?
    var raycastVizModel: ModelEntity?
    var targetVizModel: ModelEntity?
    var positionVizModel: ModelEntity?
    var normalsVizModel: ModelEntity?
    var pitchVizModel: ModelEntity?
    var yawVizModel: ModelEntity?
    var parabolaEntity: AnchorEntity?

    var pathfindingBehavior: PathfindingBehavior?

    weak var gameManager: GameManager?
    var scene: Scene!
    var entity: Entity!
    public weak var delegate: PathfindingComponentDelegate?

    public mutating func startPathfinding() {
        // Initialize component variables
        guard let arView = gameManager?.viewController?.arView else { return }
        scene = arView.scene

        // Initialize nested transforms if required
        if !(scene.anchors.contains { $0 == positionEntity }) {
            scene.addAnchor(positionEntity)
            normalPlaneEntity.setParent(positionEntity)
            yawEntity.setParent(normalPlaneEntity)
        }

        // Align our pathfinding transforms with the Creature
        resetNestedTransforms()
        // Initial kickoff
        if Options.enableTapToPlace.value {
            // If a creature is spawned in "tap to place" mode,
            // we want the creature to stay where it is for a bit
            // unless the player approaches it.
            changeToBehavior(.idle)
        } else {
            // If a creature is spawned in random mode,
            // we don't want it to wait around for the Player
            // before triggering its initial movements.
            changeToBehavior(.crawl)
        }
        // Viz Debug
        if Options.debugPathfinding.value {
            createVisualizations()
        }
    }

    public mutating func updatePathfinding(baseSpeed: Float, deltaTime: Float) {
        // Update trail
        guard let behavior = pathfindingBehavior else { return }
        if behavior.requiresTrail {
            if let entityWithVoxelTrail = entity as? HasVoxelTrail {
                entityWithVoxelTrail.updateTrail(progress: inverseLerpSpeed(baseSpeed: baseSpeed))
            }
        }
        // Check if the Creature's current behavior should be interrupted by "fear"
        let isCrawlingTowardsPlayer = (behavior.behaviorType == .crawl && isFacingPlayer())
        let isIdle = behavior.behaviorType == .idle
        let canTurnAway = isCrawlingTowardsPlayer || isIdle
        if canTurnAway && hasEnoughFearToTurnAway() {
            behavior.cancel()
            changeToBehavior(.turnaway)
        } else if !behavior.updateWithSuccess(deltaTime) {
            // Proceed to next behavior if necessary
            nextBehavior()
        } else {
            // Move Creature along with Pathfinding Entities
            entity.setPosition(.zero, relativeTo: yawEntity)
            entity.setOrientation(simd_quatf.identity, relativeTo: yawEntity)
        }
    }

    mutating public func stopPathfinding() {
        // Remove any visualizations
        if Options.debugPathfinding.value {
            destroyVisualizations()
        }
        // Stop the behavior if it still exists
        guard let currentBehavior = pathfindingBehavior else { return }
        if currentBehavior.behaviorState != .end {
            currentBehavior.cancel()
        }
        pathfindingBehavior = nil
    }

    /// Upon completion of the current behavior, this function chooses the next behavior
    mutating func nextBehavior() {
        switch pathfindingBehavior?.behaviorType {
        case .turnaway, .rotate:
            changeToBehavior([.crawl].randomElement()!)
        case .idle, nil:
            changeToBehavior([.rotate, .hop].randomElement()!)
        case .crawl:
            changeToBehavior([.idle, .rotate].randomElement()!)
        case .hop:
            changeToBehavior([.crawl, .rotate].randomElement()!)
        }
    }

    /// Called when switching to a new behavior
    mutating func changeToBehavior(_ newBehaviorType: PathfindingBehavior.BehaviorType) {
        // The player can disable various pathfinding behaviors. Let's ensure
        // the selection has not been disabled:
        if PathfindingBehavior.isLegalBehaviorType(newBehaviorType) {
            if let creature = entity as? CreatureEntity {
                pathfindingBehavior = PathfindingBehavior.generateBehavior(for: newBehaviorType,
                                                                           with: creature)
            }
        } else {
            let legalBehaviorType = PathfindingBehavior.anyLegalBehaviorType
            log.debug("Substituting %s because it's currently disabled. Using: %s",
                      "\(newBehaviorType)", "\(legalBehaviorType)")
            if let creature = entity as? CreatureEntity {
            pathfindingBehavior = PathfindingBehavior.generateBehavior(for: legalBehaviorType,
                                                                       with: creature)
            }
        }

        guard let pathfindingBehavior = pathfindingBehavior else { return }
        delegate?.behaviorChanged(pathfindingBehavior.behaviorType)
    }

    /// This function determines if the `Entity` is facing the player within a threshold of rotation
    func isFacingPlayer() -> Bool {
        // The Camera is the Player; get the Camera's position
        guard let cameraPos = gameManager?.viewController?.arView.cameraTransform.translation else { return false }
        // Transform the Camera's position from World space to the Creature's local space
        var localCameraPos = normalPlaneEntity.convert(position: cameraPos, from: nil)
        // By setting the Camera height to 0, we are in effect projecting onto the Creature's normal plane
        localCameraPos.y = 0
        // Since the camera position is now in local space, we don't need to turn it into
        // a direction vector: It already can act as one.
        // Meanwhile, the yawEntity's forward vector is also in local space.
        let dotProduct = dot(yawEntity.transform.matrix.forwardVector,
                             normalize(localCameraPos))
        // We'll consider any angle less than 90 degrees to be "facing the player".
        return dotProduct <= 0
    }

    func hasEnoughFearToTurnAway() -> Bool {
        // The Camera is the Player
        return distanceToCamera() <= Options.innerFearRadius.value
    }

    func distanceToCamera() -> Float {
        guard let arView = gameManager?.viewController?.arView else { return 100.0 }
        return distance(arView.cameraTransform.translation,
                        entity.position(relativeTo: nil))
    }

    func inverseLerpSpeed(baseSpeed: Float) -> Float {
        let minimum = Options.creatureSpeedMetersPerSecond.minimum ?? 0.0
        let maximum = Options.creatureSpeedMetersPerSecond.maximum ?? 1.0
        return (baseSpeed - minimum) / (maximum - minimum)
    }

    /// This function snaps the nested transform system to the current position and rotation of the `Entity`
    mutating func resetNestedTransforms() {
        // Move the nested transform root to the proper position
        positionEntity.position = entity.position(relativeTo: nil)
        // Break down the orientation of the creature into XZ and Y rotations
        let totalRotation = entity.orientation(relativeTo: nil)
        // Extract yaw from the total rotation in order to strip it out
        let yawOnly = totalRotation.yaw()
        // Note: If there is no yaw component to this rotation, inverting it will
        // generate a NaN.
        if yawOnly.inverse.real.isNaN {
            // If there is no yaw component, the XZ rotation is simply the total Rotation
            normalPlaneEntity.orientation = entity.orientation(relativeTo: nil)
        } else {
            // If there is a valid yaw component, strip it out by multiplying total Rotation
            // by its inverse. This leaves us with just the XZ rotation.
            normalPlaneEntity.orientation = entity.orientation(relativeTo: nil) * yawOnly.inverse
        }
        // Set the Y rotation
        yawEntity.orientation = yawOnly
    }

    /// Creates visualizations to help understand the path finding workflow
    mutating func createVisualizations() {
        createPoseVisualizations()
        createRaycastVisualizations()
        createTargetVisualizations()
        createParabolaVisualizations()
    }

    /// Helps us see the pose of the path finding result
    mutating func createPoseVisualizations() {
        // Box dimensions we'll be using
        let majorAxisSize: Float = 0.3
        let minorAxisSize: Float = 0.01
        // White Sphere for the AnchorEntity
        positionVizModel = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.04),
                                       materials: [SimpleMaterial(color: .white,
                                                                  isMetallic: false)])
        guard let positionModel = positionVizModel else { return }
        positionEntity.addChild(positionModel)
        // Green Axis Up for the Normals entity
        let yAxisBox = SIMD3<Float>(minorAxisSize, majorAxisSize * Float(2), minorAxisSize)
        normalsVizModel = ModelEntity(mesh: MeshResource.generateBox(size: yAxisBox),
                                      materials: [SimpleMaterial(color: .systemGreen,
                                                                 isMetallic: false)])
        normalPlaneEntity.addChild(normalsVizModel!)
        // Blue Axis Forward for the Yaw entity
        let zAxisBox = SIMD3<Float>(minorAxisSize, minorAxisSize, majorAxisSize)
        yawVizModel = ModelEntity(mesh: MeshResource.generateBox(size: zAxisBox),
                                  materials: [SimpleMaterial(color: .systemBlue,
                                                             isMetallic: false)])
        yawEntity.addChild(yawVizModel!)
        // Red Axis right for the pitch entity
        let xAxisBox = SIMD3<Float>(majorAxisSize, minorAxisSize, minorAxisSize)
        pitchVizModel = ModelEntity(mesh: MeshResource.generateBox(size: xAxisBox),
                                    materials: [SimpleMaterial(color: .systemRed,
                                                               isMetallic: false)])
        yawEntity.addChild(pitchVizModel!)
    }

    /// Helps us see what the Raycast hits look like during our Pathfinding routine
    mutating func createRaycastVisualizations() {
        // Box dimensions we'll be using
        let majorAxisSize: Float = 0.3
        let minorAxisSize: Float = 0.01
        // Create an `AnchorEntity` for everything to live under, and add it to the scene
        raycastVizEntity = AnchorEntity()
        gameManager?.viewController?.arView.scene.addAnchor(raycastVizEntity!)
        // Create a Cyan orb to show where the Raycast hit point is
        raycastVizModel = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.03),
                                      materials: [SimpleMaterial(color: .cyan,
                                                                 isMetallic: false)])
        raycastVizEntity!.addChild(raycastVizModel!)
        // Create three axes to illustrate the orientation of the normal at the
        // raycast hit point. Forward Axis is cyan
        let forwardAxisBox = SIMD3<Float>(minorAxisSize, minorAxisSize, majorAxisSize)
        let raycastVizFwd = ModelEntity(mesh: MeshResource.generateBox(size: forwardAxisBox),
                                        materials: [SimpleMaterial(color: .cyan,
                                                                   isMetallic: false)])
        raycastVizModel!.addChild(raycastVizFwd)
        // Right Axis is magenta
        let rightAxisBox = SIMD3<Float>(majorAxisSize, minorAxisSize, minorAxisSize)
        let raycastVizRight = ModelEntity(mesh: MeshResource.generateBox(size: rightAxisBox),
                                          materials: [SimpleMaterial(color: .magenta,
                                                                     isMetallic: false)])
        raycastVizModel!.addChild(raycastVizRight)
        // Up Axis is yellow
        let upAxisBox = SIMD3<Float>(minorAxisSize, majorAxisSize, minorAxisSize)
        let raycastVizUp = ModelEntity(mesh: MeshResource.generateBox(size: upAxisBox),
                                       materials: [SimpleMaterial(color: .yellow,
                                                                  isMetallic: false)])
        raycastVizModel!.addChild(raycastVizUp)
        // Put a little sphere on the positive part of the Up Axis, to emphasize the surface normal
        let raycastVizUpPos = ModelEntity(mesh: MeshResource.generateSphere(radius: minorAxisSize * Float(2)),
                                          materials: [SimpleMaterial(color: .yellow,
                                                                     isMetallic: false)])
        raycastVizUp.addChild(raycastVizUpPos)
        raycastVizUpPos.setPosition(SIMD3<Float>(0, majorAxisSize / 2, 0), relativeTo: raycastVizUp)
        raycastVizModel!.setPosition(entity.position, relativeTo: nil)
    }

    /// This function helps us see the Pathfinding Targets, which represents
    /// where the Creature is trying to get to when it first changes direction
    mutating func createTargetVisualizations() {
        // Box dimensions we'll be using
        let majorAxisSize: Float = 2
        let minorAxisSize: Float = 0.01
        // This Anchor will be the parent of the "Locator" shape we are creating
        targetVizEntity = AnchorEntity()
        // Generate the Right Axis model
        let rightAxisBox = SIMD3<Float>(majorAxisSize, minorAxisSize, minorAxisSize)
        targetVizModel = ModelEntity(mesh: MeshResource.generateBox(size: rightAxisBox),
                                                     materials: [SimpleMaterial(color: .red, isMetallic: false)])
        // Generate the Up Axis model as a child of the Right Axis
        let upAxisBox = SIMD3<Float>(minorAxisSize, majorAxisSize, minorAxisSize)
        let targetVizModely = ModelEntity(mesh: MeshResource.generateBox(size: upAxisBox),
                                          materials: [SimpleMaterial(color: .green, isMetallic: false)])
        targetVizModely.setParent(targetVizModel!)
        // Generate the Forward Axis model as a child of the Right Axis
        let forwardAxisBox = SIMD3<Float>(minorAxisSize, minorAxisSize, majorAxisSize)
        let targetVizModelz = ModelEntity(mesh: MeshResource.generateBox(size: forwardAxisBox),
                                          materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        targetVizModelz.setParent(targetVizModel!)
        // Add the parent model to the Anchor Entity, and add the Anchor to the Scene
        targetVizEntity!.addChild(targetVizModel!)
        targetVizModel!.setPosition(entity.position, relativeTo: nil)
        scene.addAnchor(targetVizEntity!)
    }

    /// This function will help us see the hop parabola of the Pathfinding result
    mutating func createParabolaVisualizations() {
        parabolaEntity = AnchorEntity()
        scene.addAnchor(parabolaEntity!)
    }

    /// Removes all debug visualizations
    func destroyVisualizations() {
        // Destroy our Pose Visualization models
        positionVizModel?.removeFromParent()
        normalsVizModel?.removeFromParent()
        pitchVizModel?.removeFromParent()
        yawVizModel?.removeFromParent()
        // Destroy our Raycast Visualization models
        raycastVizEntity?.removeFromParent()
        targetVizEntity?.removeFromParent()
        // Destroy our hop parabola Visualization models
        parabolaEntity?.removeFromParent()
        // Reset any Text we were using to empty
        gameManager?.viewController?.messageLabel.text = ""
    }
}

public protocol PathfindingComponentDelegate: AnyObject {
    func behaviorChanged(_ behavior: PathfindingBehavior.BehaviorType)
}

public protocol HasPathfinding where Self: Entity {}

public extension HasPathfinding where Self: Entity {
    var pathfinding: PathfindingComponent {
        get { return components[PathfindingComponent.self] ?? PathfindingComponent() }
        set { components[PathfindingComponent.self] = newValue }
    }
}
