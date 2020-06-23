/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Tunes SceneKit lighting/shadows using the entity definitions file.
*/

import Foundation
import simd
import SceneKit
import os.log

struct GameLightProps {
    var shadowMapSize = SIMD2<Float>(2048, 4096)
    var angles = SIMD3<Float>(-90, 0, 0)
    var shadowMode: Int = 0
}

class GameLight {
    private var props = GameLightProps()
    private var node: SCNNode
    
    init(_ node: SCNNode) {
        self.node = node
    }
    
    func updateProps() {
        
        guard let obj = node.gameObject else { return }
        
        // use the props data, or else use the defaults in the struct above
        if let shadowMapSize = obj.propSIMD2Float("shadowMapSize") {
            props.shadowMapSize = shadowMapSize
        }
        if let angles = obj.propSIMD3Float("angles") {
            let toRadians = Float.pi / 180.0
            props.angles = angles * toRadians
        }
        if let shadowMode = obj.propInt("shadowMode") {
            props.shadowMode = shadowMode
        }
    }
    
    func transferProps() {
        // are euler's set at refeference (ShadowLight) or internal node (LightNode)
        let lightNode = node.childNode(withName: "LightNode", recursively: true)!
        let light = lightNode.light!
    
        // As shadow map size is reduced get a softer shadow but more acne
        // and bias results in shadow offset.  Mostly thin geometry like the boxes
        // and the shadow plane have acne.  Turn off z-writes on the shadow plane.
        
        switch props.shadowMode {
        case 0:
            // activate special filtering mode with 16 sample fixed pattern
            // this slows down the rendering by 2x
            light.shadowRadius = 0
            light.shadowSampleCount = 16
            
        case 1:
            light.shadowRadius = 3 // 2.5
            light.shadowSampleCount = 8
        
        case 2:
            // as resolution decreases more acne, use bias and cutoff in shadowPlane shaderModifier
            light.shadowRadius = 1
            light.shadowSampleCount = 1
            
        default:
            os_log(.error, "unknown shadow mode")
        }
        
        // when true, this reduces acne, but is causing shadow to separate
        // not seeing much acne, so turn it off for now
        light.forcesBackFaceCasters = false
        
        light.shadowMapSize = CGSize(width: CGFloat(props.shadowMapSize.x),
                                     height: CGFloat(props.shadowMapSize.y))
        
        // Can turn on cascades with auto-adjust disabled here, but not in editor.
        // Based on shadowDistance where next cascade starts.  These are the defaults.
        // light.shadowCascadeCount = 2
        // light.shadowCascadeSplittingFactor = 0.15
        
        // this is a square volume that is mapped to the shadowMapSize
        // may need to adjust this based on the angle of the light and table size
        // setting angles won't work until we isolate angles in the level file to a single node
        // lightNode.parent.angles = prop.angles
        light.orthographicScale = 15.0
        light.zNear = 1.0
        light.zFar = 30.0
    }
}

