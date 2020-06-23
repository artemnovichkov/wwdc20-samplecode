/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Game View Controller Delegate
*/

import Foundation
import RealityKit
import ARKit

protocol GameViewControllerDelegate: AnyObject {
    func onSceneUpdated(_ arView: ARView, deltaTimeInterval: TimeInterval)
}
