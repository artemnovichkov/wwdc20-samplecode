/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Protocols for event interactions.
*/

import Foundation
import SceneKit
import ARKit

enum InteractionState: Int, Codable {
    case began, update, ended
}

protocol InteractionDelegate: class {
    var currentPlayer: Player { get }
    var physicsWorld: SCNPhysicsWorld { get }
    var projectileDelegate: ProjectileDelegate { get }
    var isServer: Bool { get }
    var allBlockObjects: [GameObject] { get }
    var catapults: [Catapult] { get }
    
    func removeTableBoxNodeFromLevel()
    
    func addNodeToLevel(_ node: SCNNode)
    func spawnProjectile() -> Projectile
    func createProjectile() -> Projectile // Create projectile without putting it into a pool, useful for using it to show when catapult gets pulled
    func gameObjectPoolCount() -> Int
    func removeAllPhysicsBehaviors()

    func addInteraction(_ interaction: Interaction)
    
    func dispatchActionToServer(gameAction: GameAction)
    func dispatchActionToAll(gameAction: GameAction) // including self
    func serverDispatchActionToAll(gameAction: GameAction)
    func dispatchToPlayer(gameAction: GameAction, player: Player)
    
    func playWinSound()
    func startGameMusic(from interaction: Interaction)
}

enum TouchType {
    case tapped
    case began
    case ended
}

protocol Interaction: class {
    init(delegate: InteractionDelegate)

    func update(cameraInfo: CameraInfo)
    
    // MARK: - Handle Inputs
    func handleTouch(_ type: TouchType, camera: Ray)

    // MARK: - Handle Action
    func handle(gameAction: GameAction, player: Player)
    
    // MARK: - Handle Collision
    func didCollision(node: SCNNode, otherNode: SCNNode, pos: SIMD3<Float>, impulse: CGFloat)
}

extension Interaction {

    func update(cameraInfo: CameraInfo) {
        
    }

    // MARK: - Handle Action
    func handle(gameAction: GameAction, player: Player) {
        
    }
    
    // MARK: - Handle Collision
    func didCollision(node: SCNNode, otherNode: SCNNode, pos: SIMD3<Float>, impulse: CGFloat) {
        
    }
}
