/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages how catapults gets disabled
*/

import Foundation
import SceneKit

class CatapultDisableInteraction: Interaction {
    weak var delegate: InteractionDelegate?
    private let catapultUnstableTimeUntilDisable = 3.0
    
    required init(delegate: InteractionDelegate) {
        self.delegate = delegate
        
        // Client should try to request the initial catapult disable state from server
        guard !delegate.isServer else { return }
        delegate.dispatchActionToServer(gameAction: .requestKnockoutSync)
    }
    
    func update(cameraInfo: CameraInfo) {
        guard let delegate = delegate else { fatalError("No Delegate") }
        
        for catapult in delegate.catapults {
            // Check and disable knocked catapults
            if !catapult.disabled && catapult.catapultKnockedTime > catapultUnstableTimeUntilDisable {
                let knockoutInfo = HitCatapult(catapultID: catapult.catapultID, justKnockedout: true, vortex: false)
                delegate.dispatchActionToAll(gameAction: .catapultKnockOut(knockoutInfo))
            }
        }
    }
    
    // MARK: - Game Action Handling
    
    func handle(gameAction: GameAction, player: Player) {
        guard let delegate = delegate else { fatalError("No Delegate") }
        
        if case .catapultKnockOut(let knockoutInfo) = gameAction {
            if let catapult = delegate.catapults.first(where: { $0.catapultID == knockoutInfo.catapultID }) {
                guard !catapult.disabled else { return }
                catapult.processKnockOut(knockoutInfo: knockoutInfo)
                catapult.isGrabbed = false
            }
        } else if case .requestKnockoutSync = gameAction, delegate.isServer {
            // Server will dispatch catapult knockout messages to all clients to make sure knockout states are in sync
            for catapult in delegate.catapults where catapult.disabled {
                let knockoutInfo = HitCatapult(catapultID: catapult.catapultID, justKnockedout: false, vortex: false)
                delegate.dispatchActionToAll(gameAction: .catapultKnockOut(knockoutInfo))
            }
        }
    }

    func handleTouch(_ type: TouchType, camera: Ray) {

    }
        
}
