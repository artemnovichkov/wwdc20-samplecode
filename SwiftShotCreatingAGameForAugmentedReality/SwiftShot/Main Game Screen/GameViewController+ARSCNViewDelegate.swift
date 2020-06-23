/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ARSCNViewDelegate methods for the Game Scene View Controller.
*/

import ARKit
import os.log

extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor == gameBoard.anchor {
            // If board anchor was added, setup the level.
            DispatchQueue.main.async {
                if self.sessionState == .localizingToBoard {
                    self.sessionState = .setupLevel
                }
            }

            // We already created a node for the board anchor
            return gameBoard
        } else {
            // Ignore all other anchors
            return nil
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let boardAnchor = anchor as? BoardAnchor {
            // Update the game board's scale from the board anchor
            // The transform will have already been updated - without the scale
            node.simdScale = SIMD3<Float>( repeating: Float(boardAnchor.size.width) )
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        os_log(.info, "camera tracking state changed to %s", "\(camera.trackingState)")
        DispatchQueue.main.async {
            self.trackingStateLabel.text = "\(camera.trackingState)"
        }
        
        switch camera.trackingState {
        case .normal:
            // Resume game if previously interrupted
            if isSessionInterrupted {
                isSessionInterrupted = false
            }
            
            // Fade in the board if previously hidden
            if gameBoard.isHidden {
                gameBoard.opacity = 1.0
                gameBoard.isHidden = false
            }
            
            // Fade in the level if previously hidden
            if renderRoot.opacity == 0.0 {
                renderRoot.opacity = 1.0
                assert(!renderRoot.isHidden)
            }
        case .limited:
            // Hide the game board and level if tracking is limited
            gameBoard.isHidden = true
            renderRoot.opacity = 0.0
        default:
            break
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Get localized strings from error
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Use `compactMap(_:)` to remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        // Present the error message to the user
        showAlert(title: "Session Error", message: errorMessage, actions: nil)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        os_log(.info, "[sessionWasInterrupted] --  %s", "\(sessionState)")
        
        // Inform the user that the session has been interrupted
        isSessionInterrupted = true
        
        // Hide game board and level
        gameBoard.isHidden = true
        renderRoot.opacity = 0.0
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        os_log(.info, "[sessionInterruptionEnded] --  %s", "\(sessionState)")
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
