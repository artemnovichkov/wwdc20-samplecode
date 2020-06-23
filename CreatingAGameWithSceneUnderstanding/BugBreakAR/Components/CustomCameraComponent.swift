/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom Camera Component
*/

import Foundation
import RealityKit

public struct CustomCameraComponent: Component {
    var aspectRatio: Float = 1
    var viewMatrix = float4x4()
    var projectionMatrix = float4x4()
    var deviceTransform = float4x4()
}
