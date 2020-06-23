/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Creature Pool
*/

import os.log
import RealityKit

class CreaturePool {

    private let log = OSLog(subsystem: appSubsystem, category: "CreaturePool")

    private let creaturePoolSize = 3
    private var creatures = [CreatureEntity]()
    private var gameManager: GameManager
    private var nestExplodeModel: Entity?
    private var shatterModel: Entity?

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        nestExplodeModel = gameManager.assets?.explodeVoxels
        shatterModel = gameManager.assets?.shatterVoxels
        for _ in 0..<creaturePoolSize {
            guard let creatureToClone = gameManager.assets?.creatureEntity else { continue }
            let newCreature = CreatureEntity.cloneCreature(creatureToClone: creatureToClone)
            newCreature.gameManager = self.gameManager
            newCreature.initialize()
            newCreature.returnToPool()
            creatures.append(newCreature)
        }
        gameManager.onAssetsLoaded()
    }

    public func initCreature(atTransform: Transform) -> CreatureEntity? {
        for index in 0..<creatures.count where
            creatures[index].isEnabled == false {
                creatures[index].placeCreature(atTransform)
                return creatures[index]
        }
        log.error("Couldn't find creature to spawn out of %d", creatures.count)
        return nil
    }

    public func enablePlayPauseVideoMaterials(_ enable: Bool) {
        creatures
            .compactMap {
                return $0.isEnabled
                    && $0.parent != nil ? $0.videoMaterialWrapper : nil
            }
            .forEach { $0.enablePlayPause(Options.playPauseVideoMaterials.value) }
    }

    public func removeAllCreatures() {
        for index in 0..<creatures.count {
            creatures[index].shutdown()
        }
        creatures.removeAll()
    }

    public var creatureEntities: [CreatureEntity] {
        creatures
            .flatMap { $0.entities }
            .compactMap { $0 as? CreatureEntity }
    }
}
