/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Tunes SceneKit camera setup using the entity definitions file.
*/

import Foundation
import simd
import SceneKit

struct GameCameraProps {
    var hdr = false
    var ambientOcclusion = 0.0
    var motionBlur = 0.0
}

class GameCamera {
    private var props = GameCameraProps()
    private var node: SCNNode
    
    init(_ node: SCNNode) {
        self.node = node
    }
    
    func updateProps() {
        guard let obj = node.gameObject else { return }
        
        // use the props data, or else use the defaults in the struct above
        if let hdr = obj.propBool("hdr") {
            props.hdr = hdr
        }
        if let motionBlur = obj.propDouble("motionBlur") {
            props.motionBlur = motionBlur
        }
        if let ambientOcclusion = obj.propDouble("ambientOcclusion") {
            props.ambientOcclusion = ambientOcclusion
        }
    }
    
    func transferProps() {
        guard let camera = node.camera else { return }

        // Wide-gamut rendering is enabled by default on supported devices;
        // to opt out, set the SCNDisableWideGamut key in your app's Info.plist file.
        camera.wantsHDR = props.hdr
        
        // Ambient occlusion doesn't work with defaults
        camera.screenSpaceAmbientOcclusionIntensity = CGFloat(props.ambientOcclusion)
        
        // Motion blur is not supported when wide-gamut color rendering is enabled.
        camera.motionBlurIntensity = CGFloat(props.motionBlur)
    }
}
