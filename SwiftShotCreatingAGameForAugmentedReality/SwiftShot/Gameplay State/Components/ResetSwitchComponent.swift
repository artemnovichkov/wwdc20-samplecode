/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Behavior for the AR reset switch.
*/

import Foundation
import GameplayKit

class ResetSwitchComponent: GKComponent, HighlightableComponent {
    let base: SCNNode
    let highlightObj: SCNNode?
    let mirrorObj: SCNNode?
    let leverObj: SCNNode
    private let leverHoldScale = SIMD3<Float>(1.2, 1.2, 1.2)
    private let leverHighlightDistance: Float = 2.5
    
    // set the angle of the lever here
    var angle: Float {
        get {
            return leverObj.simdEulerAngles.x
        }
        set {
            leverObj.simdEulerAngles.x = newValue
            
            // apply to outline component
            if let mirror = mirrorObj {
                mirror.simdEulerAngles.x = newValue
            }
        }
    }
    
    var isHighlighted: Bool {
        guard let highlight = highlightObj else { return false }
        return !highlight.isHidden
    }
    
    init(entity: GameObject, lever: SCNNode) {
        base = entity.objectRootNode
        leverObj = lever
        
        // find outline node to mirror highlighting
        if let highlightNode = entity.objectRootNode.childNode(withName: "Highlight", recursively: true),
            let mirrorOutline = highlightNode.childNode(withName: "resetSwitch_leverOutline", recursively: true) {
                highlightObj = highlightNode
                mirrorObj = mirrorOutline
        } else {
            highlightObj = nil
            mirrorObj = nil
        }
        super.init()
    }
    
    // convenience function to return which side of center the lever is on, so we can flip the
    func pullOffset(cameraOffset: SIMD3<Float>) -> SIMD3<Float> {
        return base.simdConvertVector(cameraOffset, from: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - HighlightableComponent
    func shouldHighlight(camera: Ray) -> Bool {
        let cameraToButtonDistance = length(leverObj.simdWorldPosition - camera.position)
        if cameraToButtonDistance > leverHighlightDistance {
            return false
        }
        return true
    }
    
    // enable/disable the highlight on this object
    func doHighlight(show: Bool, sfxCoordinator: SFXCoordinator?) {
        // turn off
        if !show {
            leverObj.simdScale = SIMD3<Float>(1.0, 1.0, 1.0)
        
            if let highlight = highlightObj {
                highlight.isHidden = true
            }
        
            if let mirror = mirrorObj {
                mirror.simdScale = SIMD3<Float>(1.0, 1.0, 1.0)
            }
         
            sfxCoordinator?.playLeverHighlight(highlighted: false)
        } else { // turn on
            leverObj.simdScale = leverHoldScale
            
            if let highlight = highlightObj {
                highlight.isHidden = false
            }
            
            if let mirror = mirrorObj {
                mirror.simdScale = leverHoldScale
            }
            
            sfxCoordinator?.playLeverHighlight(highlighted: true)
        }
    }
}
