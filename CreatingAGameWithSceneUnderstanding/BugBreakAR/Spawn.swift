/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Spawn
*/

import RealityKit
import ARKit
import Combine

class Spawn {
    private weak var gameManager: GameManager?

    init(gameManager: GameManager) {
        self.gameManager = gameManager
    }

    // Pick random point on spatial mesh to find a spawn position
    func searchForSpawnTransform(_ arView: ARView) {
        let spawnQueue = DispatchQueue(label: "spawn-queue")
        spawnQueue.async { [weak self] in
            var pointFound = false
            while let self = self, pointFound == false, !Options.enableTapToPlace.value, self.gameManager != nil {
                guard let currentFrame = arView.session.currentFrame,
                !currentFrame.anchors.isEmpty else { continue }

                let randomAnchorIndex = Int.random(in: 0..<currentFrame.anchors.count)
                guard let meshAnchor = currentFrame.anchors[randomAnchorIndex] as? ARMeshAnchor else { continue }
                let randomMeshIndex = Int.random(in: 0..<meshAnchor.geometry.faces.count)
                let centerOfFaceLocalPoint = meshAnchor.geometry.centerOf(faceWithIndex: randomMeshIndex)
                var centerOfFaceLocalMatrix = matrix_identity_float4x4
                centerOfFaceLocalMatrix.columns.3 = SIMD4<Float>(centerOfFaceLocalPoint.x,
                                                                 centerOfFaceLocalPoint.y,
                                                                 centerOfFaceLocalPoint.z, 1)
                let centerOfFaceWorldPoint = (meshAnchor.transform * centerOfFaceLocalMatrix).position
                let cameraPosition = arView.cameraTransform.translation
                let fromCameraToFace = centerOfFaceWorldPoint - cameraPosition
                let newQuery = ARRaycastQuery(origin: cameraPosition,
                                              direction: normalize(fromCameraToFace),
                                              allowing: .estimatedPlane, alignment: .any)
                if let newHit = arView.session.raycast(newQuery).first {
                    let newTransform = Transform(matrix: newHit.worldTransform)
                    // Check for backface: We want to make sure if we look at this face from
                    // the camera position, that we're looking at the front of the face.
                    if dot(newTransform.matrix.upVector, fromCameraToFace) <= 0 {
                        pointFound = true
                        DispatchQueue.main.async {
                            self.onSpawnTransformFound(newTransform)
                        }
                    }
                }
            }
        }
    }

    func onSpawnTransformFound(_ transform: Transform) {
        gameManager?.onSpawnPointFound(transform)
    }
}
