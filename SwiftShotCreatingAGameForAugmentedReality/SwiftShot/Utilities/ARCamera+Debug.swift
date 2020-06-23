/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for human readable ARCamera tracking state.
*/

import ARKit

extension ARCamera.TrackingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notAvailable:
            return "notAvailable"
        case .limited(let reason):
            return "limited(\(reason))"
        case .normal:
            return "normal"
        }
    }
}

extension ARCamera.TrackingState.Reason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .initializing:
            return "initializing"
        case .excessiveMotion:
            return "excessiveMotion"
        case .insufficientFeatures:
            return "insufficientFeatures"
        case .relocalizing:
            return "relocalizing"
        default:
            fatalError(#function + " - Unexpected camera tracking state reason.")
        }
    }
}
