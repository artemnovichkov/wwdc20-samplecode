/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Voxel Structures
*/

import Foundation
import RealityKit
import Combine

final class VoxelStructures {
    var explode: Entity?
    var shatter: Entity?

    static func loadVoxelStructuresAsync() -> AnyPublisher<VoxelStructures, Error> {
        return loadExplodeVoxels()
            .zip(loadShatterVoxels()).tryMap { explode, shatter in
                let voxelStructures = VoxelStructures()
                voxelStructures.explode = explode
                voxelStructures.shatter = shatter
                return voxelStructures
            }
            .eraseToAnyPublisher()
    }

    static func loadExplodeVoxels() -> AnyPublisher<Entity, Error> {
        return Entity.loadAsync(named: Constants.voxelNestExplosionName).tryMap { nestExplode in
            return nestExplode
        }
        .eraseToAnyPublisher()
    }

    static func loadShatterVoxels() -> AnyPublisher<Entity, Error> {
        return Entity.loadAsync(named: Constants.creatureShatterName).tryMap { shatter in
            return shatter
        }
        .eraseToAnyPublisher()
    }

    static func cloneNestExplode(explodeModel: Entity, transformMatrix: float4x4, scene: Scene ) {
        let explodeModel = explodeModel.clone(recursive: true)
        let explodeAnchor = AnchorEntity(world: transformMatrix)
        explodeAnchor.addChild(explodeModel)
        scene.addAnchor(explodeAnchor)
        // In this structured nest explode model, we need
        // to loop through its children to give them physics
        // and to allow them to collide with our environment
        explodeModel.visit { entity in
            if let physicsEntity = entity as? Entity & HasPhysics {
                physicsEntity.physicsBody?.mode = .dynamic
                entity.components[CollisionComponent.self]?.filter = CollisionFilter.default
                let xForceVal = Float.random(in: Constants.explodeXZRange) * Options.nestExplodeMultiplier.value
                let yForceVal = Float.random(in: Constants.explodeYRange) * Options.nestExplodeMultiplier.value
                let zForceVal = Float.random(in: Constants.explodeXZRange) * Options.nestExplodeMultiplier.value
                let forceVector = SIMD3<Float>(xForceVal,
                                               yForceVal,
                                               zForceVal)
                physicsEntity.addForce(forceVector, relativeTo: nil)
            }
        }

        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (_) in
            explodeAnchor.removeChild(explodeModel)
            scene.removeAnchor(explodeAnchor)
        }

        // Animate scaling down the pieces after a couple seconds to
        // make them disappear
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { (_) in
            let interval = TimeInterval(Options.shatterScaleOut.value)
            for index in 0..<explodeModel.children.count {
                var scaleTransform = explodeModel.children[index].transform
                scaleTransform.scale = .zero
                explodeModel.children[index].move(to: scaleTransform,
                                            relativeTo: nil,
                                            duration: interval,
                                            timingFunction: .easeInOut)
            }
        }
    }

    static func cloneShatter(shatterModel: Entity, creature: CreatureEntity, gameManager: GameManager) {
        // Sanity-check
        guard let scene = gameManager.viewController?.arView.scene else { return }
        // Get the shatter model
        let shatterModel = shatterModel.clone(recursive: true)
        let shatterAnchor = AnchorEntity(world: creature.transformMatrix(relativeTo: nil))
        shatterAnchor.addChild(shatterModel)
        scene.addAnchor(shatterAnchor)

        // Disable creature entity to make it appear
        // that it shattered
        gameManager.removeCreature(creature)
        if let audio = gameManager.assets?.audioResources[Constants.creatureDestroyAudioName] {
            shatterModel.playAudioAsync(audio)
        }

        let removeInterval = TimeInterval(Options.shatterDuration.value + Options.shatterScaleOut.value)
        Timer.scheduledTimer(withTimeInterval: removeInterval, repeats: false) { (_) in
            shatterAnchor.removeChild(shatterModel)
            scene.removeAnchor(shatterAnchor)
        }

        // In this structured shatter model, we need
        // to loop through its children to give them physics
        // and to allow them to collide with our environment
        shatterModel.visit { entity in
            if let physicsEntity = entity as? Entity & HasPhysics {
                physicsEntity.physicsBody?.mode = .dynamic
                physicsEntity.components[CollisionComponent.self]?.filter = CollisionFilter.default
                // Applying a cool "explode" force
                let xForceVal = Float.random(in: Constants.shatterXZRange) * Options.shatterForceMultiplier.value
                let yForceVal = Float.random(in: Constants.shatterYRange) * Options.shatterForceMultiplier.value
                let zForceVal = Float.random(in: Constants.shatterXZRange) * Options.shatterForceMultiplier.value
                let forceVector = SIMD3<Float>(xForceVal,
                                               yForceVal,
                                               zForceVal)
                physicsEntity.addForce(forceVector, relativeTo: nil)
            }
        }

        // Animate scaling down the pieces after a couple seconds to
        // make them disappear
        let interval = TimeInterval(Options.shatterDuration.value)
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { (_) in
            let interval = TimeInterval(Options.shatterScaleOut.value)
            for index in 0..<shatterModel.children.count {
                var scaleTransform = shatterModel.children[index].transform
                scaleTransform.scale = .zero
                shatterModel.children[index].move(to: scaleTransform,
                                            relativeTo: nil,
                                            duration: interval,
                                            timingFunction: .easeInOut)
            }
        }
    }
}
