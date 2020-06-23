/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Global Struct
*/

import UIKit

enum Constants {
    static let accelerometerFramesPerSecond: Float = 60 // for requesting accelerometer update frequency
    // fling feel scale constant
    static let flingVerticalScale: Float = 11.94
    //Audio Assets
    static let popAudioName = "Pop.wav"
    static let spawnAudioName = "Spawn.wav"
    static let idleAudioName = "Idling.wav"
    static let walkAudioName = "Walking.wav"
    static let flutterAudioName = "Flutter.wav"
    static let struggleAudioName = "Struggle.wav"
    static let tractorBeamActivateAudioName = "TractorBeamActivate.wav"
    static let tractorBeamLoopAudioName = "TractorBeamLoop.wav"
    static let creatureDestroyAudioName = "GlitchDestroy.wav"
    static let wooshAudioName = "Whoosh.wav"
    // 3D Assets
    static let creatureRcName = "Glitch_mdl"
    static let creatureWalkAnimName = "GlitchWalk_anm"
    static let creatureIdleAnimName = "GlitchIdle_anm"
    static let creatureCalmIdleAnimName = "GlitchCalmIdle_anm"
    static let creatureEntranceAnimName = "GlitchEntrance_anm"
    static let creatureFlutterAnimName = "GlitchFlutter_anm"
    static let creatureShatterName = "GlitchShatter"
    static let voxelNestExplosionName = "NestExplosion"
    static let voxelModelName = "Voxel_White"
    static let voxelCageName = "Voxel_Cage"
    static let voxelBaseColorName = "voxelBaseColor"
    static let voxelMetallicName = "voxelMetallic"
    static let voxelRoughnessName = "voxelRoughness"
    // We are not simply using creatureEntity.visualBounds(relativeTo: nil).extents
    // because the initial visual bounds are much larger than the bounding box
    // we are interested in.
    static let creatureShape = SIMD3<Float>(0.28, 0.15, 0.32)
    static let creatureLegsPositionAsRatio: Float = 0.3888
    // 2D Assets
    static let voxelBaseColorGreyValue: CGFloat = 0.6
    static let radar2DLocation = CGRect(x: 22.5, y: 22.5, width: 250, height: 250)
    // Physics related
    static let explodeXZRange: ClosedRange<Float> = -0.3...0.3
    static let explodeYRange: ClosedRange<Float> = 0.2...0.4
    static let shatterXZRange: ClosedRange<Float> = -0.1...0.1
    static let shatterYRange: ClosedRange<Float> = 0.1...0.3
}
