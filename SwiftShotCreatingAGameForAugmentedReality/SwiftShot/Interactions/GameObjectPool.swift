/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Projectile reuse to support multiplayer physics sync.
*/

import Foundation
import SceneKit

protocol GameObjectPoolDelegate: class {
    var gamedefinitions: [String: Any] { get }
    func onSpawnedProjectile()
}

// Pool that makes it possible for clients to join the game after a ball has been shot
// In this case, the pool helps manage fixed projectile slots used for physics sync.
// The pool do not actually reuse the object (that functionality could be added if necessary).
class GameObjectPool {
    private(set) var projectilePool = [Projectile]()
    private(set) var initialPoolCount = 0
    
    private let cannonball: SCNNode
    private let chicken: SCNNode
    private var chickenFeathers: SCNNode?
    
    private weak var delegate: GameObjectPoolDelegate?
    weak var projectileDelegate: ProjectileDelegate?
    
    init() {
        cannonball = SCNNode.loadSCNAsset(modelFileName: "projectiles_ball")
        chicken = SCNNode.loadSCNAsset(modelFileName: "projectiles_chicken")
        
        initialPoolCount = 30
    }
    
    func spawnProjectile() -> Projectile {
        var count = 0
        for projectile in projectilePool where !projectile.isAlive {
            count += 1
        }
        
        for projectile in projectilePool where !projectile.isAlive {
            return spawnProjectile(objectIndex: projectile.index)
        }
        fatalError("No more free projectile in the pool")
    }
    
    // Spawn projectile with specific object index
    func spawnProjectile(objectIndex: Int) -> Projectile {
        guard let delegate = delegate else { fatalError("No Delegate") }
        delegate.onSpawnedProjectile()
        
        for (poolIndex, projectile) in projectilePool.enumerated() where projectile.index == objectIndex {
            let newProjectile = createProjectile(for: .cannonball, index: projectile.index)
            newProjectile.isAlive = true
            projectilePool[poolIndex] = newProjectile
            newProjectile.delegate = projectileDelegate
            newProjectile.onSpawn()
            return newProjectile
        }
        fatalError("Could not find projectile with index: \(objectIndex)")
    }
    
    func despawnProjectile(_ projectile: Projectile) {
        projectile.disable()
    }
    
    func createPoolObjects(delegate: GameObjectPoolDelegate) {
        self.delegate = delegate
        for _ in 0..<initialPoolCount {
            let newProjectile = createProjectile(for: .cannonball, index: nil)
            projectilePool.append(newProjectile)
        }
    }
    
    func createProjectile(for projectileType: ProjectileType, index: Int?) -> Projectile {
        guard let delegate = delegate else { fatalError("No Delegate") }

        let projectile: Projectile
        switch projectileType {
        case .cannonball:
            projectile = TrailBallProjectile(prototypeNode: cannonball, index: index, gamedefs: delegate.gamedefinitions)
        // Add other projectile types here as needed
        case .chicken:
            projectile = ChickenProjectile(prototypeNode: chicken, index: index, gamedefs: delegate.gamedefinitions)
        default:
            fatalError("Trying to get .none projectile")
        }
        projectile.addComponent(RemoveWhenFallenComponent())
        return projectile
    }
}
