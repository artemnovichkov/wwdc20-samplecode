/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Creature Entity
*/

import Combine
import Foundation
import os.log
import RealityKit

public class CreatureEntity: Entity, HasPhysics, HasModel, HasCollision, HasPhysicsMotion,
                             HasVoxelTrail, HasAudioComponent {

    let log = OSLog(subsystem: appSubsystem, category: "CreatureEntity")

    enum State {
        case none,
        spawning,
        pathfinding,
        tractorBeamReelIn,
        tractorBeamed,
        released,
        destroying
    }

    var entranceAnim: Entity?
    var walkAnim: Entity?
    var idleAnim: Entity?
    var calmIdleAnim: Entity?
    var flutterAnim: Entity?
    let creatureMass: Float = 0.015
    var videoMaterialWrapper: VideoMaterialWrapper?
    var currentAnimationState: AnimationState = .none
    weak var gameManager: GameManager?
    var currentState: State = .none

    internal var arView: ARView?
    internal var collisionBeganObserver: Cancellable!
    internal var originalCreatureScale: SIMD3<Float>?

    // Movement properties
    public let birthday = Date().timeIntervalSinceReferenceDate
    internal var creatureBaseSpeed: Float!
    internal var creatureMaxFearScalar: Float = 1
    // Define a scale for `fearScalar`. Super fast creatures could get out of
    // control otherwise. The speed-up needs to be visible even on super slow creatures.
    let minFearScalar: Float = 1.2
    let maxFearScalar: Float = 2
    // The amount of clearance the Creature reasonably requires to make a 180 degree turn
    let imaginaryTurnRadius: Float = 0.08

    static func loadAsync() -> AnyPublisher<CreatureEntity, Error> {
        return loadCreatureAnimsAsync().map { creatureAnims in
            let creatureEntity = CreatureEntity()
            creatureEntity.name = Constants.creatureRcName
            creatureEntity.configurePhysicsAndCollision()
            creatureEntity.entranceAnim = creatureAnims[0]
            creatureEntity.entranceAnim?.name = Constants.creatureEntranceAnimName
            creatureEntity.addChild(creatureAnims[0])
            creatureEntity.walkAnim = creatureAnims[1]
            creatureEntity.walkAnim?.name = Constants.creatureWalkAnimName
            creatureEntity.addChild(creatureAnims[1])
            creatureEntity.idleAnim = creatureAnims[2]
            creatureEntity.idleAnim?.name = Constants.creatureIdleAnimName
            creatureEntity.addChild(creatureAnims[2])
            creatureEntity.calmIdleAnim = creatureAnims[3]
            creatureEntity.calmIdleAnim?.name = Constants.creatureCalmIdleAnimName
            creatureEntity.addChild(creatureAnims[3])
            creatureEntity.flutterAnim = creatureAnims[4]
            creatureEntity.flutterAnim?.name = Constants.creatureFlutterAnimName
            creatureEntity.addChild(creatureAnims[4])

            return creatureEntity
        }
        .eraseToAnyPublisher()
    }

    static func loadCreatureAnimsAsync() -> AnyPublisher<[Entity], Error> {
        return Entity.loadAsync(named: Constants.creatureEntranceAnimName)
            .append(Entity.loadAsync(named: Constants.creatureWalkAnimName))
            .append(Entity.loadAsync(named: Constants.creatureIdleAnimName))
            .append(Entity.loadAsync(named: Constants.creatureCalmIdleAnimName))
            .append(Entity.loadAsync(named: Constants.creatureFlutterAnimName))
            .collect()
            .tryMap { loadedEntities in
                var creatureAnims = [Entity]()
                creatureAnims.append(loadedEntities[0])
                creatureAnims.append(loadedEntities[1])
                creatureAnims.append(loadedEntities[2])
                creatureAnims.append(loadedEntities[3])
                creatureAnims.append(loadedEntities[4])
                return creatureAnims
            }
            .eraseToAnyPublisher()
    }

    static func cloneCreature(creatureToClone: CreatureEntity) -> CreatureEntity {
        let newCreature = creatureToClone.clone(recursive: true)
        newCreature.name = Constants.creatureRcName
        for index in 0..<newCreature.children.count {
            switch newCreature.children[index].name {
            case Constants.creatureEntranceAnimName:
                newCreature.entranceAnim = newCreature.children[index]
            case Constants.creatureWalkAnimName:
                newCreature.walkAnim = newCreature.children[index]
            case Constants.creatureIdleAnimName:
                newCreature.idleAnim = newCreature.children[index]
            case Constants.creatureCalmIdleAnimName:
                newCreature.calmIdleAnim = newCreature.children[index]
            case Constants.creatureFlutterAnimName:
                newCreature.flutterAnim = newCreature.children[index]
            default:
                break
            }
        }
        return newCreature
    }

    private func configurePhysicsAndCollision() {
        // Collision and physics
        let creatureBox = ShapeResource.generateBox(size: Constants.creatureShape)
        // Slip the collision bounding box backwards, because the model's pivot is not its center of mass
        let creatureCenterPivotAsRatio: Float = 0.5 // Pivot is centered in Z
        let offsetAsRatio = creatureCenterPivotAsRatio - Constants.creatureLegsPositionAsRatio
        let zOffset = -(Constants.creatureShape.z * offsetAsRatio)
        // Slip the collision bounding box upwards, because the model's pivot is at it's feet (ground height)
        let yOffset = Constants.creatureShape.y / 2
        let offsetCollisionShape = creatureBox.offsetBy(translation: SIMD3<Float>(0, yOffset, zOffset))
        collision = CollisionComponent(shapes: [offsetCollisionShape])
        collision?.filter = CollisionFilter(group: CollisionGroup(rawValue: 15), mask: CollisionGroup.all)
        collision?.mode = .default

        physicsBody = PhysicsBodyComponent(shapes: [offsetCollisionShape], mass: creatureMass, mode: .kinematic)
        physicsBody?.material = .generate(friction: 0.5, restitution: 0.9)
        physicsMotion = PhysicsMotionComponent()
    }

    public func shutdown() {
        pathfinding.pathfindingBehavior = nil
        pathfinding.gameManager = nil
        pathfinding.scene = nil
        pathfinding.entity = nil
        shutdownInteraction()
        shutdownEntitySwitcher()
        collisionBeganObserver.cancel()
        collisionBeganObserver = nil
    }
}

// Contains game logic for the bug creature
extension CreatureEntity {
    public func initialize() {
        arView = gameManager?.viewController?.arView
        guard let scene = arView?.scene else { return }

        // Component configurarion & initialization
        voxelTrail.voxels = gameManager?.voxels
        installVideoMaterial()
        configureAnimations(scene: scene)
        configureAudio()
        configureInteraction()
        configurePathfinding()

        originalCreatureScale = scale
        gameManager?.creaturesAnchor.addChild(self)

        // Yaw randomly
        let randomAngle: Float = Float.random(in: 0...Float.pi * 2)
        let randomYaw = simd_quatf(angle: randomAngle, axis: [0, 1, 0])
        setOrientation(randomYaw, relativeTo: self)

        setupInteractiveLights()

        collisionBeganObserver = arView?.scene.subscribe(to: CollisionEvents.Began.self, on: self, { event in
            self.onCollisionBegan(objectHit: event.entityB)})

        setCreatureBaseSpeed()
    }

    public func configureAudio() {
        guard let audioResources = gameManager?.assets?.audioResources else { return }
        addSound(audioResources[Constants.spawnAudioName], name: Constants.spawnAudioName)
        addSound(audioResources[Constants.idleAudioName], name: Constants.idleAudioName)
        addSound(audioResources[Constants.walkAudioName], name: Constants.walkAudioName)
        addSound(audioResources[Constants.flutterAudioName], name: Constants.flutterAudioName)
        addSound(audioResources[Constants.struggleAudioName], name: Constants.struggleAudioName)
    }

    public func returnToPool() {
        if currentState == .pathfinding {
            pathfinding.stopPathfinding()
        }
        currentState = .none
        setAnimation(animation: .none)
        resetPhysics()
        stopAllAudio()
        resetPhysicsTransform()
        physicsBody?.mode = .kinematic
        setPosition(.zero, relativeTo: gameManager?.creaturesAnchor)
        resetVideoMaterial()
        enableTractorBeamLight(false)
        updateWhackableStatus(false)
        isEnabled = false
    }

    public func placeCreature(_ pointTransform: Transform) {
        isEnabled = true
        changeCreatureScale()
        setPosition(pointTransform.translation, relativeTo: nil)
        setOrientation(pointTransform.rotation, relativeTo: nil)
        beginSpawn()
        videoMaterialWrapper?.enablePlayPause(Options.playPauseVideoMaterials.value)
    }

    private func beginSpawn() {
        currentState = .spawning
        setAnimation(animation: .entering)
        playSound(name: Constants.spawnAudioName)
        if Options.nestExplodeFX.value {
            guard let model = gameManager?.assets?.explodeVoxels else { return }
            guard let scene = arView?.scene else { return }
            VoxelStructures.cloneNestExplode(explodeModel: model,
                                             transformMatrix: transformMatrix(relativeTo: nil), scene: scene)
        }
    }

    public func updateLoop(_ deltaTime: Float) {
        videoMaterialWrapper?.sceneUpdate()
        switch currentState {
        case .pathfinding:
            pathfinding.updatePathfinding(baseSpeed: creatureBaseSpeed, deltaTime: deltaTime)
            checkForLostGlitch()
            updateWhackableStatus()
        case .tractorBeamReelIn:
            if let targetPosition = gameManager?.inputSystemInstance?.worldspaceTouchPosition() {
                updateTractorBeamReelIn(deltaTime: deltaTime, entityPosition: targetPosition)
            }
            updateWhackableStatus()
        case .tractorBeamed:
            if let targetPosition = gameManager?.inputSystemInstance?.worldspaceTouchPosition() {
                updateCarriedState(targetPosition)
            }
        case .released:
            checkForLostGlitch()
        default:
            break
        }
        // Debug visualizations
        if Options.debugPathfinding.value {
            var msgLabelText = "State: \(currentState)"
            if let behaviorType = pathfinding.pathfindingBehavior?.behaviorType {
                msgLabelText += "\nBehavior: \(behaviorType)"
            } else {
                msgLabelText += "\nBehavior: nil"
            }
            gameManager?.viewController?.messageLabel.text = msgLabelText
        }
    }

    public func onDebugPathfindingOptionsUpdated() {
        if Options.debugPathfinding.value {
            pathfinding.createVisualizations()
        } else {
            pathfinding.destroyVisualizations()
        }
    }

    public func onPathfindingEnablerUpdated() {
        if Options.enablePathfinding.value && currentState == .none {
            pathfinding.startPathfinding()
            currentState = .pathfinding
        } else if !Options.enablePathfinding.value && currentState == .pathfinding {
            pathfinding.stopPathfinding()
            currentState = .none
            setAnimation(animation: Options.calmIdleAnimation.value ? .calmIdling : .idling)
        }
    }

    public func updateShaderDebug() {
        entities.forEach { $0.shaderDebug(Options.cycleShaderDebug.value) }
    }

    private func checkForLostGlitch() {
        let pos = position(relativeTo: nil)
        let height = pos.y
        if height.isNaN || height < -5 || height > 5 {
            log.error(" ! ! ! ! ! ! ! Illegal Glitch Height (+5m radius or NaN), presumed lost:")
            log.error("                 Raw Height: %d, Raw Position: %s", height, "\(pos.dotTwoDescription)")
            gameManager?.removeCreature(self)
        }
    }

    func inverseLerpSpeed() -> Float {
        let minimum = Options.creatureSpeedMetersPerSecond.minimum ?? 0.0
        let maximum = Options.creatureSpeedMetersPerSecond.maximum ?? 1.0
        return (creatureBaseSpeed - minimum) / (maximum - minimum)
    }

    public func distanceToCamera() -> Float? {
        guard let cameraPosition = arView?.cameraTransform.translation else { return nil }
        return distance(cameraPosition, position(relativeTo: nil))
    }

    public func distanceToCameraSquared() -> Float? {
        guard let cameraPosition = arView?.cameraTransform.translation else { return nil }
        return distance_squared(cameraPosition, position(relativeTo: nil))
    }

    public func fromCameraToCreature() -> SIMD3<Float>? {
        guard let cameraPosition = arView?.cameraTransform.translation else { return nil }
        return position(relativeTo: nil) - cameraPosition
    }

    public func isCameraFacingCreature() -> Bool {
        // If we score at least an 8/10 for how directly we are facing the
        // creature, we shall say we are facing the Creature.
        guard let distance = fromCameraToCreature() else { return false }
        guard let cameraForward = arView?.cameraTransform.matrix.forwardVector else { return false }
        let thresholdForFacingCreature: Float = 0.8
        let dotProduct = dot(normalize(distance), cameraForward)
        return dotProduct >= thresholdForFacingCreature
    }

    public func setCreatureBaseSpeed() {
        let variableSpeed = Options.creatureSpeedVariation.value
        let randomSample = Float.random(in: -variableSpeed...variableSpeed)
        let minimum = Options.creatureSpeedMetersPerSecond.minimum ?? 0.0
        let maximum = Options.creatureSpeedMetersPerSecond.maximum ?? 1.0
        creatureBaseSpeed = clampValue(Options.creatureSpeedMetersPerSecond.value * (1.0 + randomSample),
                                       minimum, maximum)
        creatureMaxFearScalar = Float.lerp(maxFearScalar, minFearScalar, progress: inverseLerpSpeed())
    }

    public func changeCreatureScale() {
        guard let originalCreatureScale = originalCreatureScale else { return }
        scale = originalCreatureScale * Options.creatureScale.value
    }

    public func radiansPerSecond() -> Float {
       return getCreatureSpeed() / imaginaryTurnRadius
    }

    public func getCreatureSpeed() -> Float {
        return creatureBaseSpeed * getFearScalar()
    }

    public func getFearScalar() -> Float {
        // The Camera is the Player. Get distance from player, assuming we have a Camera
        guard let distanceToPlayer = distanceToCamera() else { return 1 }
        if distanceToPlayer <= Options.innerFearRadius.value {
            // If player is in the inner fear radius, we will scale the
            // creature's speed by the maximum allowed value.
            return creatureMaxFearScalar
        } else if Options.outerFearRadius.value == Options.innerFearRadius.value {
            // If player is not in the inner fear radius, and the inner fear
            // radius equals the outer fear radius, player is not in either fear
            // radius and speed is not impacted at all: Return scalar value of 1.
            return 1
        }
        // Determine our progress towards the inner fear radius, from the outside in.
        // [---Player--------[---Inner Radius--- (Creature) ------------------]-----------------]
        // [{    }-----------[---...
        //      ^ Player has come this far into the Outer Radius. We want the ratio of how far they've traveled:
        let ratio = (distanceToPlayer - Options.innerFearRadius.value)
                / (Options.outerFearRadius.value - Options.innerFearRadius.value)
        // This ratio was measured from the Creature outward. We are interested in measuring it from the edge of
        // the Outer Radius inward, so invert the ratio:
        let progress = Float(1 - ratio)
        // Our scalar will be anywhere from 1 (does nothing) to maximum allowed value:
        return Float.lerp(1, creatureMaxFearScalar, progress: clampValue(progress, 0, 1))
    }

    private func onCollisionBegan(objectHit: Entity) {
        if objectHit is (Entity & HasSceneUnderstanding) {
            if currentState == .released {
                log.debug("Destroying Creature: Collision with %s", "\(objectHit.name)")
                destroyCreature()
            }
        }
    }

    internal func destroyCreature() {
        if currentState != .destroying {
            currentState = .destroying
            resetPhysics()
            physicsBody?.mode = .kinematic
            DispatchQueue.main.async {
                guard let shatterModel = self.gameManager?.assets?.shatterVoxels else { return }
                guard let gameManager = self.gameManager else { return }
                VoxelStructures.cloneShatter(shatterModel: shatterModel,
                                             creature: self,
                                             gameManager: gameManager)
            }
        }
    }

    public var entities: [Entity] {
        var list = [Entity]()
        if let entranceAnim = entranceAnim { list.append(entranceAnim) }
        if let walkAnim = walkAnim { list.append(walkAnim) }
        if let idleAnim = idleAnim { list.append(idleAnim) }
        if let calmIdleAnim = calmIdleAnim { list.append(calmIdleAnim) }
        if let flutterAnim = flutterAnim { list.append(flutterAnim) }
        return list
    }
}
