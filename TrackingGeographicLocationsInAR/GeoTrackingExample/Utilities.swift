/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extensions and helpers.
*/

import MapKit
import ARKit
import RealityKit

// A map overlay for geo anchors the user has added.
class AnchorIndicator: MKCircle {
    convenience init(center: CLLocationCoordinate2D) {
        self.init(center: center, radius: 3.0)
    }
}

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        get {
            return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
        }
        set (newValue) {
            columns.3.x = newValue.x
            columns.3.y = newValue.y
            columns.3.z = newValue.z
        }
    }
}

extension Entity {
    static func placemarkEntity(for arAnchor: ARAnchor) -> AnchorEntity {
        let placemarkAnchor = AnchorEntity(anchor: arAnchor)
        
        let sphereIndicator = generateSphereIndicator(radius: 0.1)
        
        // Move the indicator up by half its height so that it doesn't intersect with the ground.
        let height = sphereIndicator.visualBounds(relativeTo: nil).extents.y
        sphereIndicator.position.y = height / 2
        
        // The move function animates the indicator to expand and rise up 3 meters from the ground like a balloon.
        // Elevated GeoAnchors are easier to see, and are high enough to stand under.
        let distanceFromGround: Float = 3
        sphereIndicator.move(by: [0, distanceFromGround, 0], scale: .one * 10, after: 0.5, duration: 5.0)
        placemarkAnchor.addChild(sphereIndicator)
        
        return placemarkAnchor
    }
    
    static func generateSphereIndicator(radius: Float) -> Entity {
        let indicatorEntity = Entity()
        let innerSphere = generateSphereModelEntity(size: radius * 0.66, color: #colorLiteral(red: 0, green: 0.3, blue: 1.4, alpha: 1), roughness: 1)
        indicatorEntity.addChild(innerSphere)
        let outerSphere = generateSphereModelEntity(size: radius, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.25), roughness: 0.3)
        indicatorEntity.addChild(outerSphere)
        
        return indicatorEntity
    }
        
    static func generateSphereModelEntity(size: Float, color: UIColor, roughness: Float) -> ModelEntity {
        let sphereMesh = MeshResource.generateSphere(radius: size)
        let material: Material
        if roughness < 1 {
            material = SimpleMaterial(color: color, roughness: MaterialScalarParameter(floatLiteral: roughness), isMetallic: true)
        } else {
            material = UnlitMaterial(color: color)
        }
        
        return ModelEntity(mesh: sphereMesh, materials: [material])
    }
    
    func move(by translation: SIMD3<Float>, scale: SIMD3<Float>, after delay: TimeInterval, duration: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            var transform: Transform = .identity
            transform.translation = self.transform.translation + translation
            transform.scale = self.transform.scale * scale
            self.move(to: transform, relativeTo: self.parent, duration: duration, timingFunction: .easeInOut)
        }
    }
}

extension ViewController {
    func alertUser(withTitle title: String, message: String, actions: [UIAlertAction]? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            if let actions = actions {
                actions.forEach { alert.addAction($0) }
            } else {
                alert.addAction(UIAlertAction(title: "OK", style: .default))
            }
            self.present(alert, animated: true)
        }
    }
    
    func showToast(_ message: String, duration: TimeInterval = 2) {
        DispatchQueue.main.async {
            self.toastLabel.numberOfLines = message.components(separatedBy: "\n").count
            self.toastLabel.text = message
            self.toastLabel.isHidden = false
            
            // use tag to tell if label has been updated
            let tag = self.toastLabel.tag + 1
            self.toastLabel.tag = tag
            
            if duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    // Do not hide if showToast is called again, before this block kicks in.
                    if self.toastLabel.tag == tag {
                        self.toastLabel.isHidden = true
                    }
                }
            }
        }
    }
}

extension ARGeoTrackingStatus.State {
    var description: String {
        switch self {
        case .notAvailable: return "Not available"
        case .initializing: return "Initializing"
        case .localizing: return "Localizing"
        case .localized: return "Localized"
        @unknown default: return  "Unknown"
        }
    }
}

extension ARGeoTrackingStatus.StateReason {
    var description: String {
        switch self {
        case .none: return "None"
        case .notAvailableAtLocation: return "Geo tracking is unavailable here. Please return to your previous location to continue"
        case .needLocationPermissions: return "App needs location permissions"
        case .worldTrackingUnstable: return "Limited tracking"
        case .geoDataNotLoaded: return "Downloading localization imagery. Please wait"
        case .devicePointedTooLow: return "Point the camera at a nearby building"
        case .visualLocalizationFailed: return "Point the camera at a building unobstructed by trees or other objects"
        case .waitingForLocation: return "ARKit is waiting for the system to provide a precise coordinate for the user"
        @unknown default: return "Unknown reason"
        }
    }
}

extension ARGeoTrackingStatus.Accuracy {
    var description: String {
        switch self {
        case .undetermined: return "Undetermined"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        @unknown default: return "Unknown"
        }
    }
}

extension ARCamera.TrackingState.Reason {
    var description: String {
        switch self {
        case .initializing: return "Initializing"
        case .excessiveMotion: return "Too much motion"
        case .insufficientFeatures: return "Insufficient features"
        case .relocalizing: return "Relocalizing"
        @unknown default: return "Unknown"
        }
    }
}
