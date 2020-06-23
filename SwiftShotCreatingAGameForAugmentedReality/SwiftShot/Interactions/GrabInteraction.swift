/*
See LICENSE folder for this sample’s licensing information.

Abstract:
User interaction for the grabbing any grabbable object.
*/

import Foundation
import SceneKit

protocol Grabbable: class {
    var grabbableID: Int { get set }
    var player: Player? { get set }
    var isGrabbed: Bool { get set }
    
    var isVisible: Bool { get }
    var isHighlighted: Bool { get }
    func doHighlight(show: Bool, sfxCoordinator: SFXCoordinator?)
    
    func canGrab(cameraRay: Ray) -> Bool
    func distanceFrom(_ worldPos: SIMD3<Float>) -> Float
    
    func move(cameraInfo: CameraInfo)
}

protocol GrabInteractionDelegate: class {
    func shouldForceRelease(grabbable: Grabbable) -> Bool
    func onServerGrab(grabbable: Grabbable, cameraInfo: CameraInfo, player: Player)
    func onGrabStart(grabbable: Grabbable, cameraInfo: CameraInfo, player: Player)
    func onServerRelease(grabbable: Grabbable, cameraInfo: CameraInfo, player: Player)
    func onUpdateGrabStatus(grabbable: Grabbable, cameraInfo: CameraInfo)
}

class GrabInteraction: Interaction {
    weak var delegate: InteractionDelegate?
    weak var grabDelegate: GrabInteractionDelegate?
    
    private(set) var grabbables = [Int: Grabbable]()
    
    var isTouching = false
    var grabbedGrabbable: Grabbable?
    
    // Index used to assign to new object
    private var currentIndex = 0
    
    required init(delegate: InteractionDelegate) {
        self.delegate = delegate
    }
    
    // Should be added only from the classes using GrabInteraction to prevent duplicates
    func addGrabbable(_ grabbable: Grabbable) {
        grabbable.grabbableID = currentIndex
        grabbables[currentIndex] = grabbable
        currentIndex += 1
    }

    func handleTouch(_ type: TouchType, camera: Ray) {
        if type == .began {
            if grabbableToGrab(cameraRay: camera) != nil {
                isTouching = true
            }
        } else if type == .ended {
            isTouching = false
        }
    }
    
    func update(cameraInfo: CameraInfo) {
        guard let delegate = delegate, let grabDelegate = grabDelegate else { fatalError("No Delegate") }
        
        // Dispatch grab action to server so that server can test if grab succeed.
        // If grab succeed, server would update the grabbable's player for all clients
        // Note:
        // This check is done in update to counter the case of network lag
        // if touch down and up is very quick, the shouldTryRelease might not trigger right at touch up,
        // because information on grabbed grabbableID might not arrived yet
        if isTouching && grabbedGrabbable == nil {
            guard GameTime.frameCount % 3 == 0 else { return } // Only send messages at 20 fps to save bandwidth
            
            // Send grab message to server if player can grab something
            if let grabbable = grabbableToGrab(cameraRay: cameraInfo.ray) {
                let grab = GrabInfo(grabbableID: grabbable.grabbableID, cameraInfo: cameraInfo)
                delegate.dispatchActionToServer(gameAction: .tryGrab(grab))
                return
            }
        }
        
        if let grabbable = grabbedGrabbable {
            if !delegate.isServer {
                // Client move the sling locally, ignore server's physics data to prevent lag
                grabbable.move(cameraInfo: cameraInfo)
            }
            
            // If touch is up or the sling is pulled too far, release the ball
            if !isTouching || grabDelegate.shouldForceRelease(grabbable: grabbable) {
                guard GameTime.frameCount % 3 == 0 else { return } // Only send messages at 20 fps to save bandwidth
                let grab = GrabInfo(grabbableID: grabbable.grabbableID, cameraInfo: cameraInfo)
                delegate.dispatchActionToServer(gameAction: .tryRelease(grab))
                return
            }
            
            // Dispatch slingMove to server.
            let data = GrabInfo(grabbableID: grabbable.grabbableID, cameraInfo: cameraInfo)
            delegate.dispatchActionToServer(gameAction: .grabMove(data))
        }
    }
    
    private func nearestVisibleGrabbable(cameraRay: Ray) -> Grabbable? {
        // Find closest visible grabbable
        var closestGrabbable: Grabbable? = nil
        var closestDist = Float(0.0)
        for grabbable in grabbables.values {
            guard grabbable.isVisible else { continue }
            
            let distance = grabbable.distanceFrom(cameraRay.position)
            if closestGrabbable == nil || distance < closestDist {
                closestGrabbable = grabbable
                closestDist = distance
            }
        }
        return closestGrabbable
    }
    
    func grabbableToGrab(cameraRay: Ray) -> Grabbable? {
        guard let grabbable = nearestVisibleGrabbable(cameraRay: cameraRay) else { return nil }
        guard grabbable.canGrab(cameraRay: cameraRay) else { return nil }
        return grabbable
    }
    
    // MARK: - Interactions
    
    func handle(gameAction: GameAction, player: Player) {
        guard let delegate = delegate else { fatalError("No delegate") }
        switch gameAction {
        // Try Grab
        case .tryGrab(let data):
            handleTryGrabAction(data: data, player: player, delegate: delegate)
        // Inform specific player of grab, when it succeeds
        case .grabStart(let data):
            handleGrabStartAction(data: data, player: player, delegate: delegate)
        // Sling Move
        case .grabMove(let data):
            handleGrabMove(data: data, player: player, delegate: delegate)
        // Try Release
        case .tryRelease(let data):
            handleTryReleaseAction(data: data, player: player, delegate: delegate)
        // Inform specific player of release
        case .releaseEnd(let data):
            handleReleaseEndAction(data: data, player: player, delegate: delegate)
        // Update Grabbable Status
        case .grabbableStatus(let status):
            handleGrabbableStatus(status: status)
        default:
            return
        }
    }
    
    // MARK: - Handle Actions
    
    private func handleTryGrabAction(data: GrabInfo, player: Player, delegate: InteractionDelegate) {
        guard let grabDelegate = grabDelegate else { fatalError("GrabDelegate not set") }

        // since we can't send a message only to the server, make sure we're the server
        // when processing.
        guard delegate.isServer else { return }
        
        // Check if player already owned a grabbable
        // This is to filter tryGrab messages a player might send because it has not received grab message yet
        for grabbable in grabbables.values {
            if let grabbablePlayer = grabbable.player, grabbablePlayer == player {
                return
            }
        }
        
        let grabbable = grabbableByID(data.grabbableID)
        grabDelegate.onServerGrab(grabbable: grabbable, cameraInfo: data.cameraInfo, player: player)
        grabbable.player = player
        
        // Inform player that the grabbable was grabbed
        let newData = GrabInfo(grabbableID: grabbable.grabbableID, cameraInfo: data.cameraInfo)
        delegate.dispatchToPlayer(gameAction: .grabStart(newData), player: player)
        
        // Update grabbable in the server and clients with a new status
        // Note: status update only sends the information on whether
        handleGrabbableStatus(status: newData)
        delegate.serverDispatchActionToAll(gameAction: .grabbableStatus(newData))
    }
    
    private func handleGrabStartAction(data: GrabInfo, player: Player, delegate: InteractionDelegate) {
        guard let grabDelegate = grabDelegate else { fatalError("GrabDelegate not set") }
        let grabbable = grabbableByID(data.grabbableID)
        grabbedGrabbable = grabbable
        grabDelegate.onGrabStart(grabbable: grabbable, cameraInfo: data.cameraInfo, player: player)
    }
    
    private func handleTryReleaseAction(data: GrabInfo, player: Player, delegate: InteractionDelegate) {
        guard let grabDelegate = grabDelegate else { fatalError("GrabDelegate not set") }
        guard delegate.isServer else { return }
        
        // Launch if player already grabbed a grabbable
        let grabbable = grabbableByID(data.grabbableID)
        guard grabbable.isGrabbed else { return }
        
        grabDelegate.onServerRelease(grabbable: grabbable, cameraInfo: data.cameraInfo, player: player)
        
        // Inform player that the grabbable was grabbed
        let newData = GrabInfo(grabbableID: grabbable.grabbableID, cameraInfo: data.cameraInfo)
        delegate.dispatchToPlayer(gameAction: .releaseEnd(newData), player: player)
    }
    
    private func handleReleaseEndAction(data: GrabInfo, player: Player, delegate: InteractionDelegate) {
        isTouching = false
    }
    
    private func handleGrabMove(data: GrabInfo, player: Player, delegate: InteractionDelegate) {
        if let grabbableID = data.grabbableID, let grabbable = grabbables[grabbableID] {
            grabbable.move(cameraInfo: data.cameraInfo)
        }
    }
    
    private func handleGrabbableStatus(status: GrabInfo) {
        guard let grabDelegate = grabDelegate else { fatalError("GrabDelegate not set") }
        guard let grabbableID = status.grabbableID, let grabbable = grabbables[grabbableID] else {
            fatalError("No Grabbable \(status.grabbableID ?? -1)")
        }
        
        grabbable.isGrabbed = true
        grabDelegate.onUpdateGrabStatus(grabbable: grabbable, cameraInfo: status.cameraInfo)
    }
    
    // MARK: - Helper
    
    private func grabbableByID(_ grabbableID: Int?) -> Grabbable {
        guard let grabbableID = grabbableID, let grabbable = grabbables[grabbableID] else {
            fatalError("Grabbable not found")
        }
        return grabbable
    }
    
}
