/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for setting shader modifier parameters on SCNMaterial or SCNGeometry.
*/

import Foundation
import SceneKit

extension SCNShadable where Self: NSObject {
    // https://developer.apple.com/documentation/scenekit/scnshadable#1654834
    // Some of these can be animated inside of an SCNTransaction.
    // Sets shader modifier data onto a material or all materials in a geometry.
    func setTexture(_ uniform: String, _ texture: SCNMaterialProperty) {
        // this must be the texture name, and not the sampler name
        setValue(texture, forKey: uniform)
    }
    
    // these repeat the type name, so if types change user can validate all type breaks
    func setfloat4x4(_ uniform: String, _ value: float4x4) {
        setValue(CATransform3D(value), forKey: uniform)
    }
    func setSIMD4Float(_ uniform: String, _ value: SIMD4<Float>) {
        setValue(SIMD4<Float>(value.x, value.y, value.z, value.w), forKey: uniform)
    }
    func setSIMD3Float(_ uniform: String, _ value: SIMD3<Float>) {
        setValue(SIMD3<Float>(value.x, value.y, value.z), forKey: uniform)
    }
    func setSIMD2Float(_ uniform: String, _ value: SIMD2<Float>) {
        setValue(CGPoint(x: CGFloat(value.x), y: CGFloat(value.y)), forKey: uniform)
    }
    func setFloat(_ uniform: String, _ value: Float) {
        setValue(CGFloat(value), forKey: uniform)
    }
    func setFloat(_ uniform: String, _ value: Double) {
        setValue(CGFloat(value), forKey: uniform)
    }
    func setInt(_ uniform: String, _ value: Int) {
        setValue(NSInteger(value), forKey: uniform)
    }
    func setColor(_ uniform: String, _ value: UIColor) {
        setValue(value, forKey: uniform)
    }
    
    // getters
    func hasUniform(_ uniform: String) -> Bool {
        return value(forKey: uniform) != nil
    }
}

