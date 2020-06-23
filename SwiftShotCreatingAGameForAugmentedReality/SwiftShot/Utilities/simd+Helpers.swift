/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extensions for SIMD vector and matrix types.
*/

import Foundation
import simd
import SceneKit

extension CATransform3D {
    init(_ m: float4x4) {
        self.init(
            m11: CGFloat(m.columns.0.x), m12: CGFloat(m.columns.1.x), m13: CGFloat(m.columns.2.x), m14: CGFloat(m.columns.3.x),
            m21: CGFloat(m.columns.0.y), m22: CGFloat(m.columns.1.y), m23: CGFloat(m.columns.2.y), m24: CGFloat(m.columns.3.y),
            m31: CGFloat(m.columns.0.x), m32: CGFloat(m.columns.1.z), m33: CGFloat(m.columns.2.z), m34: CGFloat(m.columns.3.z),
            m41: CGFloat(m.columns.0.w), m42: CGFloat(m.columns.1.w), m43: CGFloat(m.columns.2.w), m44: CGFloat(m.columns.3.w)
        )
    }
}

extension float4x4 {
    var translation: SIMD3<Float> {
        get {
            return columns.3.xyz
        }
        set(newValue) {
            columns.3 = SIMD4<Float>(newValue, 1)
        }
    }
    
    var scale: SIMD3<Float> {
        return SIMD3<Float>(length(columns.0), length(columns.1), length(columns.2))
    }

    init(translation vector: SIMD3<Float>) {
        self.init(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(vector.x, vector.y, vector.z, 1))
    }
    
    init(scale factor: Float) {
        self.init(scale: SIMD3<Float>(repeating: factor))
    }
    init(scale vector: SIMD3<Float>) {
        self.init(SIMD4<Float>(vector.x, 0, 0, 0),
                  SIMD4<Float>(0, vector.y, 0, 0),
                  SIMD4<Float>(0, 0, vector.z, 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }
    
    static let identity = matrix_identity_float4x4
}

func normalize(_ matrix: float4x4) -> float4x4 {
    var normalized = matrix
    normalized.columns.0 = simd.normalize(normalized.columns.0)
    normalized.columns.1 = simd.normalize(normalized.columns.1)
    normalized.columns.2 = simd.normalize(normalized.columns.2)
    return normalized
}

extension SIMD4 where Scalar == Float {
    static let zero = SIMD4<Float>(repeating: 0.0)
    
    var xyz: SIMD3<Float> {
        get {
            return SIMD3<Float>(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    
    init(_ xyz: SIMD3<Float>, _ w: Float) {
        self.init(xyz.x, xyz.y, xyz.z, w)
    }
    
    var hasNaN: Bool {
        return x.isNaN || y.isNaN || z.isNaN || w.isNaN
    }
    
    func almostEqual(_ value: SIMD4<Float>, within tolerance: Float) -> Bool {
        return length(self - value) <= tolerance
    }
}

extension SIMD3 where Scalar == Float {
    var hasNaN: Bool {
        return x.isNaN || y.isNaN || z.isNaN
    }
    
    func almostEqual(_ value: SIMD3<Float>, within tolerance: Float) -> Bool {
        return length(self - value) <= tolerance
    }
}

extension Float {
    func normalizedAngle(forMinimalRotationTo angle: Float, increment: Float) -> Float {
        var normalized = self
        while abs(normalized - angle) > increment / 2 {
            if self > angle {
                normalized -= increment
            } else {
                normalized += increment
            }
        }
        return normalized
    }
}
