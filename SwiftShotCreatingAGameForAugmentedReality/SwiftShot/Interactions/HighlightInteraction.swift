/*
See LICENSE folder for this sample’s licensing information.

Abstract:
User interaction for the grabbing any grabbable object.
*/

import Foundation
import SceneKit

class HighlightInteraction: Interaction {
    weak var delegate: InteractionDelegate?
    var grabInteraction: GrabInteraction?
    var sfxCoordinator: SFXCoordinator?

    required init(delegate: InteractionDelegate) {
        self.delegate = delegate
    }
    
    func update(cameraInfo: CameraInfo) {
        guard !UserDefaults.standard.spectator else { return }
        guard let grabInteraction = grabInteraction else { fatalError("GrabInteraction not set") }
        
        // Get the current nearest grabbable
        let nearestGrabbable = grabInteraction.grabbableToGrab(cameraRay: cameraInfo.ray)
        let grabbables = grabInteraction.grabbables.values
        
        // If player already grab something, we should turn off all highlight silently
        if grabInteraction.grabbedGrabbable != nil {
            for grabbable in grabbables where grabbable.isHighlighted {
                grabbable.doHighlight(show: false, sfxCoordinator: nil)
            }
            return
        }
        
        // Turn on/off highlight with sound
        for grabbable in grabbables {
            var isNearestGrabbable = false
            if let nonNilNearestGrabbable = nearestGrabbable,
                grabbable.grabbableID == nonNilNearestGrabbable.grabbableID {
                isNearestGrabbable = true
            }
            
            if isNearestGrabbable && !grabbable.isHighlighted {
                grabbable.doHighlight(show: true, sfxCoordinator: sfxCoordinator)
            } else if !isNearestGrabbable && grabbable.isHighlighted {
                grabbable.doHighlight(show: false, sfxCoordinator: sfxCoordinator)
            }
        }
    }

    func handleTouch(_ type: TouchType, camera: Ray) {

    }
}
