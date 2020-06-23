/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Options settings menu
*/

import os.log
import RealityKit
import UIKit

protocol OptionsSettingsDelegate: AnyObject {
    // Glitch Variables
    func optionsSettingsUpdateCreaturesBaseSpeed()
    func optionsSettingsUpdateCreatureScale()
    // Glitch Behaviors
    // Game Variables
    // Debug Visualizations
    func optionsSettings(enableDisable: Bool, debugOptions: ARView.DebugOptions)
    func optionsSettings(enableDisable: Bool, renderOptions: ARView.RenderOptions)
    func optionsSettings(enableDisable: Bool,
                         sceneUnderstandingOptions: ARView.Environment.SceneUnderstanding.Options)
    func optionsSettingsUpdatePathfindingVisuals()
    func optionsSettingsUpdatePathfindingEnabled()
    func optionsSettingsUpdateRadarViewVisuals()
    func optionsSettingsUpdateIBL()
    func optionsSettingsUpdateEnvironmentTexturing()
    func optionsSettingsUpdatePlayPauseVideoMaterials()
    func optionsSettingsUpdateShaderDebug()
    func optionsSettingsUpdateCameraExposure()
}

class OptionsSettings {

    private let log = OSLog(subsystem: appSubsystem, category: "OptionsSettings")

    private static let shared = OptionsSettings()

    private weak var delegate: OptionsSettingsDelegate?
    private weak var debugSettingsViewController: DebugSettingsViewController?

    static func onSequeToDebugSettingsViewController(_ destination: DebugSettingsViewController,
                                                     delegate newDelegate: OptionsSettingsDelegate? = nil) {
        destination.preferredContentSize.width = 400
        shared.debugSettingsViewController = destination
        shared.delegate = newDelegate
    }

    static func onDebugSettingsViewControllerDismiss() {
        shared.debugSettingsViewController = nil
        shared.delegate = nil
        Options.save()
    }

    static func configureDebugSetting() {
        shared.configureDebugSetting()
    }

    private func clampFearValues(_ clampOuterRadiusFirst: Bool) {
        if Options.outerFearRadius.value < Options.innerFearRadius.value {
            if clampOuterRadiusFirst {
                Options.outerFearRadius.value = Options.innerFearRadius.value
            } else {
                Options.innerFearRadius.value = Options.outerFearRadius.value
            }
        }
    }

    func configureDebugSetting() {
        log.debug("Configuring Options Settings Popover")

        var prototypes: [DebugSettingPrototype] = []

        // Glitch Variables
        prototypes += [
            DebugSettingPrototype(.section("Creature Variables"))
        ]

        prototypes += [
            DebugSettingPrototype(Options.enablePathfinding) { [weak self] _ in
                self?.delegate?.optionsSettingsUpdatePathfindingEnabled()
                return false
            }
        ]

        // Game Variables
        prototypes += [
            DebugSettingPrototype(sampleCode: false, Options.maxCreatureInstances)
        ]
        prototypes += [
            DebugSettingPrototype(Options.showRadar) { [weak self] _ in
                self?.delegate?.optionsSettingsUpdateRadarViewVisuals()
                return false
            },
            DebugSettingPrototype(Options.showRadarIntro)
        ]

        // DebugVisualizations
        prototypes += [
            DebugSettingPrototype(.section("Debug Visualizations")),
            DebugSettingPrototype(Options.showSpatialMesh) { [weak self] newValue in
                self?.delegate?.optionsSettings(enableDisable: newValue,
                                                debugOptions: .showSceneUnderstanding)
                return false
            },
            DebugSettingPrototype(Options.showPhysicsMesh) { [weak self] newValue in
                self?.delegate?.optionsSettings(enableDisable: newValue,
                                                debugOptions: .showPhysics)
                return false
            },
            DebugSettingPrototype(Options.activateOcclusion) { [weak self] newValue in
                self?.delegate?.optionsSettings(enableDisable: newValue,
                                                sceneUnderstandingOptions: .occlusion)
                return false
            },
            DebugSettingPrototype(Options.showDepthOfField) { [weak self] newValue in
                self?.delegate?.optionsSettings(enableDisable: !newValue,
                                                renderOptions: .disableDepthOfField)
                return false
            },
            DebugSettingPrototype(Options.showMotionBlur) { [weak self] newValue in
                self?.delegate?.optionsSettings(enableDisable: !newValue,
                                                renderOptions: .disableMotionBlur)
                return false
            },
            DebugSettingPrototype(Options.showCameraGrain) { [weak self] newValue in
                self?.delegate?.optionsSettings(enableDisable: !newValue,
                                                renderOptions: .disableCameraGrain)
                return false
            },
            DebugSettingPrototype(Options.showShadows) { [weak self] newValue in
                self?.delegate?.optionsSettings(enableDisable: newValue,
                                                sceneUnderstandingOptions: .receivesLighting)
                return false
            },
            DebugSettingPrototype(Options.debugPathfinding) { [weak self] _ in
                self?.delegate?.optionsSettingsUpdatePathfindingVisuals()
                return false
            },
            DebugSettingPrototype(Options.enableTouchTrail),
            DebugSettingPrototype(Options.enableIBL) { [weak self] _ in
                self?.delegate?.optionsSettingsUpdateIBL()
                return false
            },
            DebugSettingPrototype(Options.enableEnvironmentTexturing) { [weak self] _ in
                self?.delegate?.optionsSettingsUpdateEnvironmentTexturing()
                return false
            },
            DebugSettingPrototype(Options.playPauseVideoMaterials) { [weak self] _ in
                self?.delegate?.optionsSettingsUpdatePlayPauseVideoMaterials()
                return false
            },
            DebugSettingPrototype(Options.cycleShaderDebug) { [weak self] _ in
                self?.delegate?.optionsSettingsUpdateShaderDebug()
                return false
            },
            DebugSettingPrototype(Options.cameraExposure) { [weak self] _ in
                self?.delegate?.optionsSettingsUpdateCameraExposure()
                return false
            }
        ]

        DebugSettings.shared.newPrototypes(prototypes)
    }
}
