/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Options
*/

import Foundation
import os.log
import RealityKit

private let log = OSLog(subsystem: appSubsystem, category: "Options")

enum ShaderDebugCycle: Int, Codable, CaseIterable {
//    typealias RawValue = Int

    case noDebug
    case showBaseColor
    case showNormals
    case showTextureCoordinates

    init?(_ rawValue: Int) {
        switch rawValue {
        case 0: self = .noDebug
        case 1: self = .showBaseColor
        case 2: self = .showNormals
        case 3: self = .showTextureCoordinates
        default: return nil
        }
    }
}

extension ShaderDebugCycle {
    var label: String {
        switch self {
        case .noDebug: return "No Debug"
        case .showBaseColor: return "Show Base Color"
        case .showNormals: return "Show Normals"
        case .showTextureCoordinates: return "Show Txt Coords"
        }
    }
}

enum Options {
    // Creature settings
    static var maxCreatureInstances = DebugSettingInt(1,
                                                      label: "Creature Count",
                                                      minimum: 1, maximum: 3)
    static var creatureSpeedMetersPerSecond = DebugSettingFloat(0.55,
                                                                label: "Creature Speed",
                                                                minimum: 0.0, maximum: 1.0)
    static var creatureScale = DebugSettingFloat(1.0,
                                                 label: "Creature Scale",
                                                 minimum: 1.0, maximum: 3.0)
    // speed *= (1.0 +/- RandomRange(creatureSpeedVariation))
    static var creatureSpeedVariation = DebugSettingFloat(0.2,
                                                          label: "Creature Speed Variation",
                                                          minimum: 0.0, maximum: 1.0)
    // This speeds the Creature up.
    static var outerFearRadius = DebugSettingFloat(1.0,
                                                   label: "Outer Fear Radius",
                                                   minimum: 0.0, maximum: 3.0)
    // This makes the Creature turn around, if applicable.
    static var innerFearRadius = DebugSettingFloat(0.2,
                                                   label: "Inner Fear Radius",
                                                   minimum: 0.0, maximum: 3.0)
    static var enableVoxelTrail = DebugSettingBool(true, label: "Enable Voxel Trail")
    // Whack interaction
    static var whackAccelerationThreshold = DebugSettingFloat(1.3,
                                                              label: "Whack Speed",
                                                              minimum: 0.0, maximum: 2.0)
    static var whackDistance = DebugSettingFloat(0.5,
                                                 label: "Whack Distance",
                                                 minimum: 0.0, maximum: 5.0)
    static var whackDistanceSqr = DebugSettingFloat(whackDistance.value * whackDistance.value)
    // Tractor beam interaction
    static var tractorBeamDistance = DebugSettingFloat(5.0,
                                                       label: "Tractor Beam Distance",
                                                       minimum: 0.25, maximum: 5.0)
    static var tractorBeamLight = DebugSettingBool(false, label: "Enable Tractor Beam Light")
    static var flingStrengthMultiplier = DebugSettingFloat(1.0,
                                                           label: "Fling Strength",
                                                           minimum: 0.5, maximum: 10.0)
    // Pathfinding Behaviors
    static var enablePathfinding = DebugSettingBool(true, label: "Enable Pathfinding")
    static var isBurrowLegal = DebugSettingBool(true, label: "Enable Burrow Behavior")
    static var isCrawlLegal = DebugSettingBool(true, label: "Enable Crawling Behavior")
    static var isHopLegal = DebugSettingBool(true, label: "Enable Hopping Behavior")
    static var isIdleLegal = DebugSettingBool(true, label: "Enable Idle Behavior")
    static var isRotateLegal = DebugSettingBool(true, label: "Enable Rotation Behavior")
    // Visualizations
    static var showSpatialMesh = DebugSettingBool(false, label: "Show Reconstruction Mesh")
    static var showPhysicsMesh = DebugSettingBool(false, label: "Show Physics Bounds")
    static var activateOcclusion = DebugSettingBool(true, label: "Enable Occlusion")
    static var showDepthOfField = DebugSettingBool(true, label: "Enable Depth of Field")
    static var showMotionBlur = DebugSettingBool(false, label: "Enable Motion Blur")
    static var showCameraGrain = DebugSettingBool(true, label: "Enable Camera Grain")
    static var showShadows = DebugSettingBool(true, label: "Enable Shadows")
    static var showRadar = DebugSettingBool(true, label: "Enable Radar")
    static var showRadarIntro = DebugSettingBool(true, label: "Enable Radar Intro")
    static var radarTransitionThreshold = DebugSettingInt(3000,
                                                          label: "Radar Tranistion Threshold",
                                                          minimum: 100, maximum: 5000)
    static var startClassificationThreshold = DebugSettingInt(10,
                                                              label: "Start Classification Threshold",
                                                              minimum: 1, maximum: 500)
    static var debugPathfinding = DebugSettingBool(false, label: "Show Pathfinding")
    static var enableTapToPlace = DebugSettingBool(true, label: "Tap to Place Creature")
    // Animation and Voxels
    static var calmIdleAnimation = DebugSettingBool(false, label: "Calm Idle")
    static var nestExplodeFX = DebugSettingBool(true, label: "Enable Nest Explosion")
    static var nestExplodeMultiplier = DebugSettingFloat(1.0,
                                                         label: "Nest Explode Force",
                                                         minimum: 0.0, maximum: 10.0)
    static var enableTouchTrail = DebugSettingBool(false, label: "Enable Touch Trail")
    static var shatterForceMultiplier = DebugSettingFloat(0.5,
                                                          label: "Shatter Force",
                                                          minimum: 0.0, maximum: 10.0)
    static var shatterDuration = DebugSettingFloat(2.0,
                                                   label: "Shatter Duration",
                                                   minimum: 0.5, maximum: 5.0)
    static let shatterScaleOut = DebugSettingFloat(2.0,
                                                   label: "Scale Out",
                                                   minimum: 0.5, maximum: 5.0)

    static var enableIBL = DebugSettingBool(true, label: "Enable IBL")
    static var enableEnvironmentTexturing = DebugSettingBool(true,
                                                             label: "Enable Environment Texturing")
    static var playPauseVideoMaterials = DebugSettingBool(true,
                                                          label: "Play/Pause Video Material",
                                                          imageNames: ["play.fill", "pause.fill"])
    static var cycleShaderDebug = DebugSettingEnum(ShaderDebugCycle.noDebug.rawValue,
                                                   label: "Cycle Shader Debug",
                                                   titles: ShaderDebugCycle.allCases.map { "\($0)" })
    static var cameraExposure = DebugSettingFloat(0.0,
                                                  label: "Camera Exposure",
                                                  minimum: -4.0, maximum: 4.0)

    static fileprivate var savedURLString = FileManager.default.urls(
        for: FileManager.SearchPathDirectory.cachesDirectory,
        in: .userDomainMask).first
    static let savedFileName = "options.json"

    public static func save() {
        guard var url = savedURLString else {
            return
        }
        url.appendPathComponent(savedFileName, isDirectory: false)

        var savedData = SavedOption()
        savedData.save()

        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(savedData)
            removePreviousOptionsFile(url)
            FileManager.default.createFile(atPath: url.path, contents: jsonData, attributes: nil)
        } catch {
            log.error("settings save error: %s", "\(error.localizedDescription)")
            return
        }
    }

    public static func load() {
        guard var url = savedURLString else {
            return
        }
        url.appendPathComponent(savedFileName, isDirectory: false)

        if !FileManager.default.fileExists(atPath: url.path) {
            log.error("No saved options detected. Going with default")
            return
        }
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            do {
                let jsonData = try decoder.decode(SavedOption.self, from: data)
                jsonData.load()
            } catch {
                log.error("settings load error: %s", "\(error.localizedDescription)")
                removePreviousOptionsFile(url)
            }
        } else {
            fatalError("No data was found at \(url.path)")
        }
    }

    public static func loadDefault() {
        let options = SavedOption()
        options.load()
    }

    private static func removePreviousOptionsFile(_ url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            log.error("remove error: %s", "\(error.localizedDescription)")
        }
    }
}

struct SavedOption: Codable {
    var maxCreatureInstances = Options.maxCreatureInstances.defaultValue
    var creatureScale: Float = Options.creatureScale.defaultValue
    var creatureSpeedMetersPerSecond: Float = Options.creatureSpeedMetersPerSecond.defaultValue
    var whackAccelerationThreshold: Float = Options.whackAccelerationThreshold.defaultValue
    var whackDistance: Float = Options.whackDistance.defaultValue
    var tractorBeamDistance: Float = Options.tractorBeamDistance.defaultValue
    var tractorBeamLight: Bool = Options.tractorBeamLight.defaultValue
    var flingStrengthMultiplier: Float = Options.flingStrengthMultiplier.defaultValue
    var debugPathfinding: Bool = Options.debugPathfinding.defaultValue
    var enableVoxelTrail: Bool = Options.enableVoxelTrail.defaultValue
    var showRadar: Bool = Options.showRadar.defaultValue
    var showRadarIntro: Bool = Options.showRadarIntro.defaultValue
    var radarTransitionThreshold: Int = Options.radarTransitionThreshold.defaultValue
    var startClassificationThreshold: Int = Options.startClassificationThreshold.defaultValue
    var enableTapToPlace: Bool = Options.enableTapToPlace.defaultValue
    var enablePathfinding: Bool = Options.enablePathfinding.defaultValue
    var isBurrowLegal: Bool = Options.isBurrowLegal.defaultValue
    var isCrawlLegal: Bool = Options.isCrawlLegal.defaultValue
    var isHopLegal: Bool = Options.isHopLegal.defaultValue
    var isIdleLegal: Bool = Options.isIdleLegal.defaultValue
    var isRotateLegal: Bool = Options.isRotateLegal.defaultValue
    var outerFearRadius: Float = Options.outerFearRadius.defaultValue
    var innerFearRadius: Float = Options.innerFearRadius.defaultValue
    var showSpatialMesh: Bool = Options.showSpatialMesh.defaultValue
    var showPhysicsMesh: Bool = Options.showPhysicsMesh.defaultValue
    var activateOcclusion: Bool = Options.activateOcclusion.defaultValue
    var showDepthOfField: Bool = Options.showDepthOfField.defaultValue
    var showMotionBlur: Bool = Options.showMotionBlur.defaultValue
    var showCameraGrain: Bool = Options.showCameraGrain.defaultValue
    var showShadows: Bool = Options.showShadows.defaultValue
    var calmIdleAnimation: Bool = Options.calmIdleAnimation.defaultValue
    var nestExplodeFX: Bool = Options.nestExplodeFX.defaultValue
    var nestExplodeMultiplier: Float = Options.nestExplodeMultiplier.defaultValue
    var shatterForceMultiplier: Float = Options.shatterForceMultiplier.defaultValue
    var shatterDuration: Float = Options.shatterDuration.defaultValue
    var enableTouchTrail: Bool = Options.enableTouchTrail.defaultValue

    var enableIBL: Bool = Options.enableIBL.defaultValue
    var enableEnvironmentTexturing: Bool = Options.enableEnvironmentTexturing.defaultValue
    var playPauseVideoMaterials: Bool = Options.playPauseVideoMaterials.defaultValue
    var cycleShaderDebug: Int = Options.cycleShaderDebug.defaultValue
    var cameraExposure: Float = Options.cameraExposure.defaultValue

    public func load() {
        Options.maxCreatureInstances.value = maxCreatureInstances
        Options.creatureScale.value = creatureScale
        Options.creatureSpeedMetersPerSecond.value = creatureSpeedMetersPerSecond
        Options.whackAccelerationThreshold.value = whackAccelerationThreshold
        Options.whackDistance.value = whackDistance
        Options.tractorBeamDistance.value = tractorBeamDistance
        Options.tractorBeamLight.value = tractorBeamLight
        Options.flingStrengthMultiplier.value = flingStrengthMultiplier
        Options.debugPathfinding.value = debugPathfinding
        Options.enableVoxelTrail.value = enableVoxelTrail
        Options.showRadar.value = showRadar
        Options.showRadarIntro.value = showRadarIntro
        Options.radarTransitionThreshold.value = radarTransitionThreshold
        Options.startClassificationThreshold.value = startClassificationThreshold
        Options.enableTapToPlace.value = enableTapToPlace
        Options.enablePathfinding.value = enablePathfinding
        Options.isBurrowLegal.value = isBurrowLegal
        Options.isCrawlLegal.value = isCrawlLegal
        Options.isHopLegal.value = isHopLegal
        Options.isIdleLegal.value = isIdleLegal
        Options.isRotateLegal.value = isRotateLegal
        Options.outerFearRadius.value = outerFearRadius
        Options.innerFearRadius.value = innerFearRadius
        Options.showSpatialMesh.value = showSpatialMesh
        Options.showPhysicsMesh.value = showPhysicsMesh
        Options.activateOcclusion.value = activateOcclusion
        Options.showDepthOfField.value = showDepthOfField
        Options.showMotionBlur.value = showMotionBlur
        Options.showCameraGrain.value = showCameraGrain
        Options.showShadows.value = showShadows
        Options.calmIdleAnimation.value = calmIdleAnimation
        Options.nestExplodeFX.value = nestExplodeFX
        Options.nestExplodeMultiplier.value = nestExplodeMultiplier
        Options.shatterForceMultiplier.value = shatterForceMultiplier
        Options.shatterDuration.value = shatterDuration
        Options.enableTouchTrail.value = enableTouchTrail

        Options.enableIBL.value = enableIBL
        Options.enableEnvironmentTexturing.value = enableEnvironmentTexturing
        Options.playPauseVideoMaterials.value = playPauseVideoMaterials
        Options.cycleShaderDebug.value = cycleShaderDebug
        Options.cameraExposure.value = cameraExposure
    }

    public mutating func save() {
        maxCreatureInstances = Options.maxCreatureInstances.value
        creatureScale = Options.creatureScale.value
        creatureSpeedMetersPerSecond = Options.creatureSpeedMetersPerSecond.value
        whackAccelerationThreshold = Options.whackAccelerationThreshold.value
        whackDistance = Options.whackDistance.value
        tractorBeamDistance = Options.tractorBeamDistance.value
        tractorBeamLight = Options.tractorBeamLight.value
        flingStrengthMultiplier = Options.flingStrengthMultiplier.value
        debugPathfinding = Options.debugPathfinding.value
        enableVoxelTrail = Options.enableVoxelTrail.value
        showRadar = Options.showRadar.value
        showRadarIntro = Options.showRadarIntro.value
        radarTransitionThreshold = Options.radarTransitionThreshold.defaultValue
        startClassificationThreshold = Options.startClassificationThreshold.defaultValue
        enableTapToPlace = Options.enableTapToPlace.value
        enablePathfinding = Options.enablePathfinding.value
        isBurrowLegal = Options.isBurrowLegal.value
        isCrawlLegal = Options.isCrawlLegal.value
        isHopLegal = Options.isHopLegal.value
        isIdleLegal = Options.isIdleLegal.value
        isRotateLegal = Options.isRotateLegal.value
        outerFearRadius = Options.outerFearRadius.value
        innerFearRadius = Options.innerFearRadius.value
        showSpatialMesh = Options.showSpatialMesh.value
        showPhysicsMesh = Options.showPhysicsMesh.value
        activateOcclusion = Options.activateOcclusion.value
        showDepthOfField = Options.showDepthOfField.value
        showMotionBlur = Options.showMotionBlur.value
        showCameraGrain = Options.showCameraGrain.value
        showShadows = Options.showShadows.value
        calmIdleAnimation = Options.calmIdleAnimation.value
        nestExplodeFX = Options.nestExplodeFX.value
        nestExplodeMultiplier = Options.nestExplodeMultiplier.value
        shatterForceMultiplier = Options.shatterForceMultiplier.value
        shatterDuration = Options.shatterDuration.value
        enableTouchTrail = Options.enableTouchTrail.value

        enableIBL = Options.enableIBL.value
        enableEnvironmentTexturing = Options.enableEnvironmentTexturing.value
        playPauseVideoMaterials = Options.playPauseVideoMaterials.value
        cycleShaderDebug = Options.cycleShaderDebug.value
        cameraExposure = Options.cameraExposure.value
    }
}
