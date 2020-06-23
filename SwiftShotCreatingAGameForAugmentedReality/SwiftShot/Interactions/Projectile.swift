/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom projectile selection.
*/

import Foundation
import SceneKit

enum ProjectileType: UInt32, CaseIterable {
    case none = 0
    case cannonball
    case chicken
    
    var next: ProjectileType {
        switch self {
        case .none: return .cannonball
        case .cannonball: return .chicken
        case .chicken: return .cannonball
        }
    }
}

protocol ProjectileDelegate: class {
    var isServer: Bool { get }
    func addParticles(_ particlesNode: SCNNode, worldPosition: SIMD3<Float>)
    func despawnProjectile(_ projectile: Projectile)
    func addNodeToLevel(node: SCNNode)
}

class Projectile: GameObject {
    var physicsBody: SCNPhysicsBody?
    var team: Team = .none {
        didSet {
            // we assume the geometry and lod are unique to geometry and lod here
            geometryNode?.geometry?.firstMaterial?.diffuse.contents = team.color
            if let levelsOfDetail = geometryNode?.geometry?.levelsOfDetail {
                for lod in levelsOfDetail {
                    lod.geometry?.firstMaterial?.diffuse.contents = team.color
                }
            }
        }
    }
    
    weak var delegate: ProjectileDelegate?
    
    private var startTime: TimeInterval = 0.0
    var isLaunched = false
    var age: TimeInterval { return isLaunched ? (GameTime.time - startTime) : 0.0 }
    
    // Projectile life time should be set so that projectiles will not be depleted from the pool
    private var lifeTime: TimeInterval = 0.0
    private let fadeTimeToLifeTimeRatio = 0.1
    private var fadeStartTime: TimeInterval { return lifeTime * (1.0 - fadeTimeToLifeTimeRatio) }

    init(prototypeNode: SCNNode, index: Int?, gamedefs: [String: Any]) {
        let node = prototypeNode.clone()
        // geometry and materials are reference types, so here we
        // do a deep copy. that way, each projectile gets its own color.
        node.copyGeometryAndMaterials()
        
        guard let physicsNode = node.findNodeWithPhysicsBody(),
            let physicsBody = physicsNode.physicsBody else {
                fatalError("Projectile node has no physics")
        }
        
        physicsBody.contactTestBitMask = CollisionMask([.rigidBody, .glitterObject, .triggerVolume]).rawValue
        physicsBody.categoryBitMask = CollisionMask([.ball]).rawValue
        
        super.init(node: node, index: index, gamedefs: gamedefs, alive: false, server: false)
        self.physicsNode = physicsNode
        self.physicsBody = physicsBody
    }

    convenience init(prototypeNode: SCNNode) {
        self.init(prototypeNode: prototypeNode, index: nil, gamedefs: [String: Any]())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func launch(velocity: GameVelocity, lifeTime: TimeInterval, delegate: ProjectileDelegate) {
        startTime = GameTime.time
        isLaunched = true
        self.lifeTime = lifeTime
        self.delegate = delegate
        
        if let physicsNode = physicsNode,
            let physicsBody = physicsBody {
            
            physicsBody.simdVelocityFactor = SIMD3<Float>(1.0, 1.0, 1.0)
            physicsBody.simdAngularVelocityFactor = SIMD3<Float>(1.0, 1.0, 1.0)
            physicsBody.simdVelocity = velocity.vector
            physicsNode.name = "ball"
            physicsNode.simdWorldPosition = velocity.origin
            physicsBody.resetTransform()
            physicsBody.continuousCollisionDetectionThreshold = 0.001
        } else {
            fatalError("Projectile not setup")
        }
    }

    func onDidApplyConstraints(renderer: SCNSceneRenderer) {}

    func didBeginContact(contact: SCNPhysicsContact) {
        
    }

    func onSpawn() {

    }

    override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)
        // Projectile should fade and disappear after a while
        if age > lifeTime {
            objectRootNode.opacity = 1.0
            despawn()
        } else if age > fadeStartTime {
            objectRootNode.opacity = CGFloat(1.0 - (age - fadeStartTime) / (lifeTime - fadeStartTime))
        }
    }
    
    func despawn() {
        guard let delegate = delegate else { fatalError("No Delegate") }
        delegate.despawnProjectile(self)
    }

    override func generatePhysicsData() -> PhysicsNodeData? {
        guard var data = super.generatePhysicsData() else { return nil }
        data.team = team
        return data
    }
}

// Chicken example of how we make a new projectile type
class ChickenProjectile: Projectile {}
