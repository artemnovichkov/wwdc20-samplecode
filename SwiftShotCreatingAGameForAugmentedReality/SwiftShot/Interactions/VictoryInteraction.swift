/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Check and display victory special effect to end the game.
*/

import Foundation
import SceneKit

class VictoryInteraction: Interaction {
    weak var delegate: InteractionDelegate?
    private(set) var displayedVictory = false
    private(set) var gameDone = false
    private var teamWon: Team = .none
    
    private var victoryNode: SCNNode
    private var activationStartTime: TimeInterval = 0.0

    private let fadeTime: TimeInterval = 0.5
    private let timeUntilPhysicsReleased = 10.0
    
    private let lock = NSLock() // need thread protection because main thread is the one that called didWin()

    required init(delegate: InteractionDelegate) {
        self.delegate = delegate
        
        victoryNode = SCNNode.loadSCNAsset(modelFileName: "victory")
    }
    
    func activateVictory() {
        guard !displayedVictory else { return }
        lock.lock() ; defer { lock.unlock() }

        guard let delegate = delegate else { fatalError("No Delegate") }
        delegate.addNodeToLevel(victoryNode)
        victoryNode.simdWorldPosition = SIMD3<Float>(0.0, 15.0, 0.0)
        
        victoryNode.simdEulerAngles.y = teamWon == .teamA ? .pi : 0.0 // Rotate Victory to face in the right direction
        for child in victoryNode.childNodes {
            child.physicsBody?.resetTransform()
        }
        displayedVictory = true
        activationStartTime = GameTime.time
        
        // Set color to that of winning team
        victoryNode.setPaintColors(team: teamWon)
        
        delegate.playWinSound()
    }
    
    func update(cameraInfo: CameraInfo) {
        if displayedVictory {
            // Enlarge victory text before falling down
            victoryNode.opacity = CGFloat(clamp((GameTime.time - activationStartTime) / fadeTime, 0.0, 1.0))
            
            if GameTime.time - activationStartTime > timeUntilPhysicsReleased {
                for child in victoryNode.childNodes {
                    child.physicsBody?.simdVelocityFactor = SIMD3<Float>(1.0, 1.0, 1.0)
                    child.physicsBody?.simdAngularVelocityFactor = SIMD3<Float>(1.0, 1.0, 1.0)
                }
            }
        } else {
            // Update win condition
            if didWin() && teamWon != .none {
                activateVictory()
            }
        }
    }

    func handleTouch(_ type: TouchType, camera: Ray) {

    }
    
    private func didWin() -> Bool {
        guard let delegate = delegate else { fatalError("No Delegate") }
        let catapults = delegate.catapults
        
        var teamToCatapultCount = [0, 0, 0]
        for catapult in catapults where !catapult.disabled {
            teamToCatapultCount[catapult.team.rawValue] += 1
        }
        
        gameDone = true
        if teamToCatapultCount[1] == 0 && teamToCatapultCount[2] == 0 {
            teamWon = .none
        } else if teamToCatapultCount[1] == 0 {
            teamWon = .teamB
        } else if teamToCatapultCount[2] == 0 {
            teamWon = .teamA
        } else {
            gameDone = false
        }
        
        return gameDone
    }

}
