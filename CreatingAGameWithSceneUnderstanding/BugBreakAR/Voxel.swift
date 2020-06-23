/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Voxel
*/

import Foundation
import RealityKit
import Combine
import UIKit

class Voxel: Equatable {
    public var coordinates: simd_int3!
    public var modelEntity: VoxelEntity?
    public var anchorEntity = AnchorEntity()
    private var entranceTime: Double = 0.2
    private var idleTime: Double = 0
    private var exitTime: Double = 2
    private var currentStateStartTime: Double = 0
    private var voxelMaterial: SimpleMaterial?
    private var voxelMaxScale: Float = 1
    private weak var voxels: Voxels?
    private let rotationOptions: [Float] = [0, Float.pi / 2, Float.pi, 1.5 * Float.pi]

    indirect enum VoxelState {
        case uninitialized
        case initialized
        case enter
        case idle
        case exit
    }
    private var currentState: VoxelState = .uninitialized

    var sceneObserver: Cancellable!

    init(_ coordinates: simd_int3,
         entranceTime: Double,
         idleTime: Double,
         exitTime: Double,
         voxels: Voxels) {

        self.voxels = voxels
        self.voxelMaterial = voxels.voxelMaterial

        // Sanity-check model is available to clone
        if let voxelToClone = voxels.voxelEntity {
            self.modelEntity = VoxelEntity.cloneVoxel(voxelToClone: voxelToClone)
            anchorEntity.addChild(self.modelEntity!)
        }

        // Calculate the scalar needed for the voxel model to become the desired size
        if let voxelModelSize = self.modelEntity?.visualBounds(relativeTo: nil).extents.x {
            self.voxelMaxScale = Voxels.voxelSize / voxelModelSize
        }

        // Randomly rotate this model
        let randomRotX = simd_quatf(angle: rotationOptions[Int.random(in: 0..<rotationOptions.count)],
                                axis: SIMD3<Float>(1, 0, 0))
        let randomRotY = simd_quatf(angle: rotationOptions[Int.random(in: 0..<rotationOptions.count)],
                                    axis: SIMD3<Float>(0, 1, 0))
        modelEntity?.orientation = randomRotX * randomRotY

        // Our Voxel Pool uses this function on the Voxels it recycles.
        // We'll use it now so as not to repeat code.
        reinitialize(coordinates,
                     entranceTime: entranceTime,
                     idleTime: idleTime,
                     exitTime: exitTime)
    }

    public func reinitialize(_ coordinates: simd_int3,
                             entranceTime: Double,
                             idleTime: Double,
                             exitTime: Double) {
        // Stored coordinates so we can reactivate this Voxel if desired
        self.coordinates = coordinates
        // How long the Voxel lives after Entering, and before Exiting
        self.entranceTime = entranceTime
        self.idleTime = idleTime
        self.exitTime = exitTime
        self.currentStateStartTime = 0

        // Anchor Entity will be parent of Redundant Anchor Entity
        anchorEntity.position = voxels!.getPosition(coordinates)
        anchorEntity.isEnabled = false

        // Subscribe to step
        let scene = voxels?.arView?.scene
        sceneObserver = scene?.subscribe(to: SceneEvents.Update.self, { _ in
            self.updateLoop()})

        currentState = .initialized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setMaterialColor(_ color: UIColor) {
        guard var voxelMaterial = voxelMaterial else { return }
        voxelMaterial.tintColor = color
        modelEntity?.model?.materials[0] = voxelMaterial
    }

    private func goToEnterState() {
        // Initialize Voxel at scale 0; we will animate it to 1 and back to zero.
        anchorEntity.scale = SIMD3<Float>.zero
        modelEntity?.position = SIMD3<Float>.zero

        // Kill any previous animation, and make sure we're visible
        self.anchorEntity.stopAllAnimations()
        anchorEntity.isEnabled = true

        // Initialize Transform we'd like to animate To
        var targetTransform = anchorEntity.transform
        targetTransform.scale = SIMD3<Float>(voxelMaxScale, voxelMaxScale, voxelMaxScale)

        // Over the span of [duration], "move" the transform to a scale of 1
        anchorEntity.move(to: targetTransform,
                          relativeTo: nil,
                          duration: entranceTime,
                          timingFunction: .easeIn)

        currentStateStartTime = NSDate().timeIntervalSince1970

        // Begin enter state
        currentState = .enter
    }

    private func goToIdleState() {
        currentStateStartTime = NSDate().timeIntervalSince1970
        currentState = .idle
    }

    private func goToExitState() {
        // Over the span of [duration], "move" the transform to a scale of 0
        var targetTransform = anchorEntity.transform
        targetTransform.scale = SIMD3<Float>.zero

        anchorEntity.move(to: targetTransform,
                          relativeTo: nil,
                          duration: exitTime,
                          timingFunction: .easeInOut)

        currentStateStartTime = NSDate().timeIntervalSince1970
        currentState = .exit
    }

    public func addForce(_ forceVector: SIMD3<Float>) {
        // Assign physics components if not yet initialized
        if !(modelEntity?.components.has(PhysicsBodyComponent.self) ?? true) {
            modelEntity?.physicsBody = PhysicsBodyComponent()
            modelEntity?.physicsMotion = PhysicsMotionComponent()
            modelEntity?.generateCollisionShapes(recursive: true)
            modelEntity?.physicsBody?.mode = .dynamic
        }

        // Assign velocity
        modelEntity?.clearForcesAndTorques()
        modelEntity?.physicsMotion?.linearVelocity = forceVector

        // Don't track this anymore (allows new Voxels to form at its initial spawn point)
        voxels?.stopTrackingVoxel(self)
    }

    public func show() {
        if anchorEntity.scene == nil {
            return
        }
        goToEnterState()
    }

    public func hide() {
        // Unsubscribe
        sceneObserver.cancel()

        // Reset state
        currentState = .uninitialized

        // Don't animate. Don't render.
        anchorEntity.stopAllAnimations()
        anchorEntity.isEnabled = false

        // Retire this Voxel to the pool
        voxels?.returnToPool(self)
    }

    // Doing this with Timers because AnimationEvents.PlaybackCompleted events seemed to be a
    // permanent state once activated: If a single animation on an Entity completes, this
    // PlaybackCompleted state will be True for anything subscribed to it, at any point in time.
    // Even if the subscription comes after another Animation has started.
    // Further, it seems that stacking these on redundant transforms also doesn't work. For example,
    // if I had a Root Anchor, a child Anchor, and then a grandchild Model, I could not simply
    // run the Animation one after another-- somehow it doesn't take.
    private func updateLoop() {
        switch currentState {
        case .uninitialized, .initialized:
            return
        case .enter:
            if NSDate().timeIntervalSince1970 - currentStateStartTime >= entranceTime {
                goToIdleState()
            }
        case .idle:
            if NSDate().timeIntervalSince1970 - currentStateStartTime >= idleTime {
                goToExitState()
            }
        case .exit:
            if NSDate().timeIntervalSince1970 - currentStateStartTime >= exitTime {
                hide()
            }
        }
    }

    static func == (lhs: Voxel, rhs: Voxel) -> Bool {
        return lhs.anchorEntity == rhs.anchorEntity
    }

    deinit {
        sceneObserver.cancel()
        sceneObserver = nil
        voxels = nil
        modelEntity = nil
    }
}
