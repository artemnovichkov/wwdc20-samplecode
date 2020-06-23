/*
See LICENSE folder for this sample’s licensing information.

Abstract:
User interaction for levers and switches.
*/

import Foundation
import SceneKit

protocol LeverInteractionDelegate: class {
    var isActivated: Bool { get }
    func activate()
}

class LeverInteraction: Interaction {
    weak var delegate: InteractionDelegate?
    var sfxCoordinator: SFXCoordinator?

    private var resetSwitches = [ResetSwitchComponent]()
    
    private var activeSwitch: ResetSwitchComponent?
    private var highlightedSwitch: ResetSwitchComponent?
    private var leverHighlight: SCNNode?
    private var startLeverHoldCameraPosition = SIMD3<Float>()
    private var startLeverEulerX: Float = 0.0

    private let leverHighlightDistance: Float = 2.5
    private let leverPullZtoLeverEulerRotation: Float = 1.0
    private let leverSpringBackSpeed: Float = 2.0
    private let leverMaxEulerX: Float = .pi / 6.0
    
    private var interactionToActivate: LeverInteractionDelegate?

    required init(delegate: InteractionDelegate) {
        self.delegate = delegate
    }
    
    func setup(resetSwitches: [GameObject], interactionToActivate: LeverInteractionDelegate) {
        for object in resetSwitches {
            guard let resetComponent = object.component(ofType: ResetSwitchComponent.self ) else { continue }
            self.resetSwitches.append(resetComponent)
        }
        self.interactionToActivate = interactionToActivate
    }

    func handleTouch(_ type: TouchType, camera: Ray) {
        if type == .began {
            guard let highlightedSwitch = highlightedSwitch else { return }
            startLeverHoldCameraPosition = camera.position
            startLeverEulerX = highlightedSwitch.angle
            activeSwitch = highlightedSwitch
        } else if type == .ended {
            activeSwitch = nil
        }
    }
    
    func handle(gameAction: GameAction, player: Player) {
        // Move the lever to received position unless this player is already holding a lever
        if case .leverMove(let data) = gameAction {
            guard resetSwitches.count > data.leverID else { fatalError("resetSwitches does not match across network") }
            if activeSwitch != resetSwitches[data.leverID] {
                resetSwitches[data.leverID].angle = data.eulerAngleX
            }
        }
    }
    
    func update(cameraInfo: CameraInfo) {
        guard let delegate = delegate else { fatalError("No delegate") }
        
        // Do not move the lever after it has been activated
        guard !(interactionToActivate?.isActivated ?? false) else { return }

        if let activeSwitch = activeSwitch {
            // Lever Pulling
            let cameraOffset = activeSwitch.pullOffset(cameraOffset: cameraInfo.ray.position - startLeverHoldCameraPosition)
            let cameraMovedZ = cameraOffset.z
            
            var targetEulerX = startLeverEulerX + leverPullZtoLeverEulerRotation * cameraMovedZ
            targetEulerX = clamp(-leverMaxEulerX, targetEulerX, leverMaxEulerX)
            activeSwitch.angle = targetEulerX
            
            if targetEulerX <= -leverMaxEulerX {
                // Interaction activation once the switch lever is turned all the way
                interactionToActivate?.activate()
                
                // Fade out the switches
                let waitAction = SCNAction.wait(duration: 3.0)
                let fadeAction = SCNAction.fadeOut(duration: 3.0)
                for resetSwitch in resetSwitches {
                    resetSwitch.base.runAction(SCNAction.sequence([waitAction, fadeAction]))
                }
                return
            } else {
                // Inform peers of the movement
                guard let leverID = resetSwitches.firstIndex(of: activeSwitch) else { fatalError("No lever in array") }
                delegate.dispatchActionToServer(gameAction: .leverMove(LeverMove(leverID: leverID, eulerAngleX: targetEulerX)))
            }
        } else {
            // Lever spring back
            for lever in resetSwitches where lever.angle < leverMaxEulerX {
                lever.angle = min(leverMaxEulerX, lever.angle + leverSpringBackSpeed * Float(GameTime.deltaTime))
            }
        }
        
        // Highlight lever when nearby, otherwise check if we should hide the highlight
        if let highlightedSwitch = highlightedSwitch {
            if !highlightedSwitch.shouldHighlight(camera: cameraInfo.ray) {
                highlightedSwitch.doHighlight(show: false, sfxCoordinator: sfxCoordinator)
                self.highlightedSwitch = nil
            }
        } else {
            for resetSwitch in resetSwitches {
                if resetSwitch.shouldHighlight(camera: cameraInfo.ray) {
                    resetSwitch.doHighlight(show: true, sfxCoordinator: sfxCoordinator)
                    highlightedSwitch = resetSwitch
                }
            }
        }
    }
}
