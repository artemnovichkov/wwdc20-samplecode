/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Voxel Assets
*/

import Foundation
import RealityKit
import Combine

class VoxelAssets {
    var modelLoadRequest: AnyCancellable!
    var textureLoadRequest: AnyCancellable!
    var baseColor: TextureResource!
    var metallic: TextureResource!
    var roughness: TextureResource!
    static var model: ModelEntity?
    static var material: SimpleMaterial!

    init() {
        modelLoadRequest = Entity.loadModelAsync(named: Constants.voxelModelName)
        .sink(receiveCompletion: { loadCompletion in
            print("Load voxel model result: \(loadCompletion)")
        }, receiveValue: { entity in
            VoxelAssets.model = entity
        })

        textureLoadRequest = TextureResource.loadAsync(named: Constants.voxelBaseColorName)
            .append(TextureResource.loadAsync(named: Constants.voxelMetallicName))
            .append(TextureResource.loadAsync(named: Constants.voxelRoughnessName))
            .collect()
            .sink(receiveCompletion: { loadCompletion in
                print("Load voxel textures result: \(loadCompletion)")
            }, receiveValue: { textures in
                self.baseColor = textures[0]
                self.metallic = textures[1]
                self.roughness = textures[2]
                self.createMaterial()
            })
    }

    func createMaterial() {
        var mat = SimpleMaterial()
        mat.baseColor = .texture(roughness)
        mat.metallic = .texture(metallic)
        mat.roughness = .texture(roughness)

        VoxelAssets.material = mat
    }

}
