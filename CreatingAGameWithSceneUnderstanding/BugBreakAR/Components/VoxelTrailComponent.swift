/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Voxel Trail Component
*/

import Foundation
import RealityKit
import Combine

public struct VoxelTrailComponent: Component {
    weak var voxels: Voxels?
    let entranceTimeFastest: Float = 0.3
    let entranceTimeSlowest: Float = 1
    let idleTimeFastest: Float = 0.6
    let idleTimeSlowest: Float = 2
    let exitTimeFastest: Float = 1.75
    let exitTimeSlowest: Float = 1.75
    let timeVariance: Double = 0.5
    var trailPositions: [SIMD3<Float>] = [SIMD3<Float>(0, 0, 0),
                                          SIMD3<Float>(-Voxels.voxelSize, 0, 0),
                                          SIMD3<Float>(Voxels.voxelSize, 0, 0)]
    var activeCoords: [simd_int3?] = [nil, nil, nil]

    public mutating func update(entity: Entity, progress: Float) {
        // If voxels is `nil` or voxel trails are disabled, return early
        guard let voxels = voxels, Options.enableVoxelTrail.value else { return }

        // Loop over trail positions and show the voxel at that coordinate
        for index in 0..<trailPositions.count {
            let point = entity.convert(position: trailPositions[index],
                                       to: nil)
            let coord = voxels.getCoordinates(point)
            if activeCoords[index] != coord {
                // Track this coordinate as an activated voxel
                activeCoords[index] = coord

                // Show the voxel
                let entranceTime = Float.lerp(entranceTimeSlowest,
                                              entranceTimeFastest,
                                              progress: progress)
                let idleTime = Float.lerp(idleTimeSlowest,
                                          idleTimeFastest,
                                          progress: progress)
                let exitTime = Float.lerp(exitTimeSlowest,
                                          exitTimeFastest,
                                          progress: progress)
                voxels.getVoxel(coord,
                                 entranceTime: Double(entranceTime) - Double.random(in: 0...timeVariance),
                                 idleTime: Double(idleTime) - Double.random(in: 0...timeVariance),
                                 exitTime: Double(exitTime) - Double.random(in: 0...timeVariance))
            }
        }
    }
}

public protocol HasVoxelTrail where Self: Entity {}

public extension HasVoxelTrail where Self: Entity {

    var voxelTrail: VoxelTrailComponent {
        get { return components[VoxelTrailComponent.self] ?? VoxelTrailComponent() }
        set { components[VoxelTrailComponent.self] = newValue }
    }

    func updateTrail(progress: Float) {
        voxelTrail.update(entity: self, progress: progress)
    }
}
