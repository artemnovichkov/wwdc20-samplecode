/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages user interactions.
*/

import Foundation
import SceneKit
import ARKit

class InteractionManager {
    private var interactions = [Int: Interaction]()
    
    func addInteraction(_ interaction: Interaction) {
        let classIdentifier = ObjectIdentifier(type(of: interaction)).hashValue
        interactions[classIdentifier] = interaction
    }

    func interaction<InteractionType>(ofType interactionClass: InteractionType.Type) -> InteractionType? where InteractionType: Interaction {
        let classIdentifier = ObjectIdentifier(interactionClass).hashValue
        if let result = interactions[classIdentifier] as? InteractionType {
            return result
        }
        return nil
    }
    
    func removeAllInteractions() {
        interactions.removeAll()
    }
    
    func updateAll(cameraInfo: CameraInfo) {
        for interaction in interactions.values {
            interaction.update(cameraInfo: cameraInfo)
        }
    }

    func handle(gameAction: GameAction, from player: Player) {
        for interaction in interactions.values {
            interaction.handle(gameAction: gameAction, player: player)
        }
    }
    
    // MARK: - Touch Event Routing
    func handleTouch(_ type: TouchType, camera: Ray) {
        for interaction in interactions.values {
            interaction.handleTouch(type, camera: camera)
        }
    }
    
    func didCollision(nodeA: SCNNode, nodeB: SCNNode, pos: SIMD3<Float>, impulse: CGFloat) {
        for interaction in interactions.values {
            // nodeA and nodeB take turn to be the main node
            interaction.didCollision(node: nodeA, otherNode: nodeB, pos: pos, impulse: impulse)
            interaction.didCollision(node: nodeB, otherNode: nodeA, pos: pos, impulse: impulse)
        }
    }
}
