/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Game View Controller AR Session Delegate
*/

import UIKit
import RealityKit
import ARKit

extension GameViewController: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        gatherRays(anchors)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    }

    public func onNewClassifications(_ categorizations: [SIMD3<Float>: ARMeshClassification]) {
        gameManager?.radarMap.addCategories(categorizations)
    }

    func gatherRays(_ anchors: [ARAnchor]) {
        guard let gameManager = gameManager, !Classifications.isUpdating && anchors.count > 1 else { return }

        // Examines newly updated anchors
        // Anchors contain: Geometry (which is made up of faces), and a classification
        // This function aggregates the centerpoint of each face, and maps it to its classification
        // These classifications are cached in the Classifications class. They are stored by their
        // voxelized location (as opposed to their precise 3d position).
        Classifications.isUpdating = true
        DispatchQueue.global().async {
            var newClassifications = [SIMD3<Float>: ARMeshClassification]()
            for anchorIndex in 0..<anchors.count {

                guard let arMeshAnchor = anchors[anchorIndex] as? ARMeshAnchor else { continue }

                for index in 0..<arMeshAnchor.geometry.faces.count {
                    let geometricCenterOfFace = arMeshAnchor.geometry.centerOf(faceWithIndex: index)
                    var centerLocalTransform = matrix_identity_float4x4
                    centerLocalTransform.columns.3 = SIMD4<Float>(geometricCenterOfFace.x,
                                                                  geometricCenterOfFace.y,
                                                                  geometricCenterOfFace.z, 1)
                    let centerWorldPosition = (arMeshAnchor.transform * centerLocalTransform).position

                    let classification = arMeshAnchor.geometry.classificationOf(faceWithIndex: index)

                    if !gameManager.radarMap.isFullScreen &&
                        (classification == .none || classification == .floor || classification == .ceiling) {
                        continue
                    }

                    // If there's no change, continue
                    if let coordinates = self.gameManager?.voxels?.getCoordinates(centerWorldPosition) {
                        if let currentClassification = Classifications.classification(coordinates),
                            currentClassification == classification {
                            continue
                        }
                    }
                    // Otherwise store the value
                    newClassifications[centerWorldPosition] = classification
                }
            }

            DispatchQueue.main.async {
                for (position, classification) in newClassifications {
                    guard let voxels = self.gameManager?.voxels else { return }
                    let coordinates = (voxels.getCoordinates(position))
                    Classifications.newClassification(coordinates,
                                                      classification: classification)
                }
                self.onNewClassifications(newClassifications)
                newClassifications.removeAll()
                Classifications.isUpdating = false
            }
        }
    }
}
