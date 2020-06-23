/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Removes nodes from the scene when they fall out of bounds.
*/

import GameplayKit
import os.log

class RemoveWhenFallenComponent: GKComponent {
    override func update(deltaTime seconds: TimeInterval) {
        guard GameTime.frameCount % 6 != 0 else { return }
        guard let gameObject = entity as? GameObject else { return }
        guard let physicsNode = gameObject.physicsNode else { return }
        // check past min/max bounds
        // the border was chosen experimentally to see what feels good
        let minBounds = SIMD3<Float>(-80.0, -10.0, -80.0) // -10.0 represents 1.0 meter high table
        let maxBounds = SIMD3<Float>(80.0, 1000.0, 80.0)
        let position = physicsNode.presentation.simdWorldPosition

        // this is only checking position, but bounds could be offset or bigger
        let shouldRemove = min(position, minBounds) != minBounds ||
            max(position, maxBounds) != maxBounds
        if shouldRemove {
            os_log(.debug, "removing node at %s", "\(position)")
            gameObject.disable()
        }
    }
}
