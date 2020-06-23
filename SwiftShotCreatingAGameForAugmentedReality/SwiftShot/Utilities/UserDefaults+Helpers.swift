/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for type safe UserDefaults access.
*/

import Foundation
import MultipeerConnectivity

struct UserDefaultsKeys {
    // debug support
    static let showSceneViewStats = "ShowSceneViewStatsKey"
    static let showWireframe = "ShowWireframe"
    static let showTrackingState = "ShowTrackingStateKey"
    static let showARDebug = "ShowARDebugKey"
    static let showPhysicsDebug = "EnablePhysicsKey"
    static let showNetworkDebug = "ShowNetworkDebugKey"
    static let showSettingsInGame = "ShowSettingsInGame"
    static let showARRelocalizationHelp = "ShowARRelocalizationHelp"
    static let trailWidth = "TrailWidth"
    static let trailLength = "TrailLength"
    static let showProjectileTrail = "ShowProjectileTrail"
    static let useCustomTrail = "UseCustomTrail"
    static let trailShouldNarrow = "TrailShouldNarrow"
    static let allowGameBoardAutoSize = "AllowGameBoardAutoSize"
    static let disableInGameUI = "DisableInGameUI"

    // settings
    static let antialiasingMode = "AntialiasingMode"
    static let peerID = "PeerIDDefaultsKey"
    static let selectedLevel = "SelectedLevel"
    static let hasOnboarded = "HasOnboarded"
    static let boardLocatingMode = "BoardLocatingMode"
    static let gameRoomMode = "GameRoomMode"
    static let autoFocus = "AutoFocus"
    static let spectator = "Spectator"

    static let showReset = "ShowReset"
    static let showClouds = "ShowClouds"
    static let showFlags = "ShowFlags"
    static let showRopeSimulation = "ShowRopeSimulation"
    static let showLOD = "showLOD"
    
    static let musicVolume = "MusicVolume"
    static let effectsVolume = "EffectsVolume"
    static let synchronizeMusicWithWallClock = "MusicSyncWithClock"
    
    static let showThermalState = "ShowThermalState"
}

extension UserDefaults {

    enum BoardLocatingMode: Int {
        case worldMap = 0 // default
        // slot 1 previously used; leave empty so that on update,
        // worldMap is used insead.
        case manual = 2
    }

    static let applicationDefaults: [String: Any] = [
        UserDefaultsKeys.spectator: false,
        UserDefaultsKeys.musicVolume: 0.0,
        UserDefaultsKeys.effectsVolume: 1.0,
        UserDefaultsKeys.antialiasingMode: true,
        UserDefaultsKeys.gameRoomMode: false,
        UserDefaultsKeys.autoFocus: true,
        UserDefaultsKeys.allowGameBoardAutoSize: false,
        UserDefaultsKeys.showReset: false,
        UserDefaultsKeys.showFlags: true,
        UserDefaultsKeys.showClouds: false,
        UserDefaultsKeys.synchronizeMusicWithWallClock: true,
        UserDefaultsKeys.showRopeSimulation: true,
        UserDefaultsKeys.showThermalState: true,
        UserDefaultsKeys.showProjectileTrail: true,
        UserDefaultsKeys.trailShouldNarrow: true
        ]

    var myself: Player {
        get {
            if let data = data(forKey: UserDefaultsKeys.peerID),
                let unarchived = ((try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data)) as MCPeerID??),
                let peerID = unarchived {
                return Player(peerID: peerID)
            }
            // if no playerID was previously selected, create and cache a new one.
            let player = Player(username: UIDevice.current.name)
            let newData = try? NSKeyedArchiver.archivedData(withRootObject: player.peerID, requiringSecureCoding: true)
            set(newData, forKey: UserDefaultsKeys.peerID)
            return player
        }
        set {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue.peerID, requiringSecureCoding: true)
            set(data, forKey: UserDefaultsKeys.peerID)
        }
    }
    
    var musicVolume: Float {
        get { return float(forKey: UserDefaultsKeys.musicVolume) }
        set { set(newValue, forKey: UserDefaultsKeys.musicVolume) }
    }

    var effectsVolume: Float {
        get { return float(forKey: UserDefaultsKeys.effectsVolume) }
        set { set(newValue, forKey: UserDefaultsKeys.effectsVolume) }
    }

    var showARDebug: Bool {
        get { return bool(forKey: UserDefaultsKeys.showARDebug) }
        set { set(newValue, forKey: UserDefaultsKeys.showARDebug) }
    }

    var showSceneViewStats: Bool {
        get { return bool(forKey: UserDefaultsKeys.showSceneViewStats) }
        set { set(newValue, forKey: UserDefaultsKeys.showSceneViewStats) }
    }

    // this is a wireframe overlay for looking at poly-count (f.e. LOD)
    var showWireframe: Bool {
        get { return bool(forKey: UserDefaultsKeys.showWireframe) }
        set { set(newValue, forKey: UserDefaultsKeys.showWireframe) }
    }
    
    // this turns shapes emissive channel red (set at level start)
    var showLOD: Bool {
        get { return bool(forKey: UserDefaultsKeys.showLOD) }
        set { set(newValue, forKey: UserDefaultsKeys.showLOD) }
    }
    
    // this may need to be integer for 0, 2, 4x
    var antialiasingMode: Bool {
        get { return bool(forKey: UserDefaultsKeys.antialiasingMode) }
        set { set(newValue, forKey: UserDefaultsKeys.antialiasingMode) }
    }

    var showTrackingState: Bool {
        get { return bool(forKey: UserDefaultsKeys.showTrackingState) }
        set { set(newValue, forKey: UserDefaultsKeys.showTrackingState) }
    }

    var selectedLevel: GameLevel {
        get {
            if let levelName = string(forKey: UserDefaultsKeys.selectedLevel),
                let level = GameLevel.level(for: levelName) {
                return level
            } else {
                return GameLevel.defaultLevel
            }
        }
        set {
            set(newValue.key, forKey: UserDefaultsKeys.selectedLevel)
        }
    }

    var showPhysicsDebug: Bool {
        get { return bool(forKey: UserDefaultsKeys.showPhysicsDebug) }
        set { set(newValue, forKey: UserDefaultsKeys.showPhysicsDebug) }
    }
    
    var showNetworkDebug: Bool {
        get { return bool(forKey: UserDefaultsKeys.showNetworkDebug) }
        set { set(newValue, forKey: UserDefaultsKeys.showNetworkDebug) }
    }
    
    var hasOnboarded: Bool {
        get { return bool(forKey: UserDefaultsKeys.hasOnboarded) }
        set { set(newValue, forKey: UserDefaultsKeys.hasOnboarded) }
    }

    var boardLocatingMode: BoardLocatingMode {
        get { return BoardLocatingMode(rawValue: integer(forKey: UserDefaultsKeys.boardLocatingMode)) ?? .worldMap }
        set { set(newValue.rawValue, forKey: UserDefaultsKeys.boardLocatingMode) }
    }

    var gameRoomMode: Bool {
        get { return bool(forKey: UserDefaultsKeys.gameRoomMode) }
        set { set(newValue, forKey: UserDefaultsKeys.gameRoomMode) }
    }
    
    var showSettingsInGame: Bool {
        get { return bool(forKey: UserDefaultsKeys.showSettingsInGame) }
        set { set(newValue, forKey: UserDefaultsKeys.showSettingsInGame) }
    }
    
    var showARRelocalizationHelp: Bool {
        get { return bool(forKey: UserDefaultsKeys.showARRelocalizationHelp) }
        set { set(newValue, forKey: UserDefaultsKeys.showARRelocalizationHelp) }
    }

    var trailLength: Int? {
        get {
            return object(forKey: UserDefaultsKeys.trailLength) as? Int
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: UserDefaultsKeys.trailLength)
            } else {
                removeObject(forKey: UserDefaultsKeys.trailLength)
            }
        }
    }

    var trailWidth: Float? {
        get {
            return object(forKey: UserDefaultsKeys.trailWidth) as? Float
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: UserDefaultsKeys.trailWidth)
            } else {
                removeObject(forKey: UserDefaultsKeys.trailWidth)
            }
        }
    }
    
    var showProjectileTrail: Bool {
        get { return bool(forKey: UserDefaultsKeys.showProjectileTrail) }
        set { set(newValue, forKey: UserDefaultsKeys.showProjectileTrail) }
    }

    var useCustomTrail: Bool {
        get { return bool(forKey: UserDefaultsKeys.useCustomTrail) }
        set { set(newValue, forKey: UserDefaultsKeys.useCustomTrail) }
    }
    
    var tailShouldNarrow: Bool {
        get { return bool(forKey: UserDefaultsKeys.trailShouldNarrow) }
        set { set(newValue, forKey: UserDefaultsKeys.trailShouldNarrow) }
    }

    var showResetLever: Bool {
        get { return bool(forKey: UserDefaultsKeys.showReset) }
        set { set(newValue, forKey: UserDefaultsKeys.showReset) }
    }
    
    var showClouds: Bool {
        get { return bool(forKey: UserDefaultsKeys.showClouds) }
        set { set(newValue, forKey: UserDefaultsKeys.showClouds) }
    }
    
    var showFlags: Bool {
        get { return bool(forKey: UserDefaultsKeys.showFlags) }
        set { set(newValue, forKey: UserDefaultsKeys.showFlags) }
    }
    
    var showRopeSimulation: Bool {
        get { return bool(forKey: UserDefaultsKeys.showRopeSimulation) }
        set { set(newValue, forKey: UserDefaultsKeys.showRopeSimulation) }
    }

    var autoFocus: Bool {
        get { return bool(forKey: UserDefaultsKeys.autoFocus) }
        set { set(newValue, forKey: UserDefaultsKeys.autoFocus) }
    }
    
    var allowGameBoardAutoSize: Bool {
        get { return bool(forKey: UserDefaultsKeys.allowGameBoardAutoSize) }
        set { set(newValue, forKey: UserDefaultsKeys.allowGameBoardAutoSize) }
    }

    var spectator: Bool {
        get { return bool(forKey: UserDefaultsKeys.spectator) }
        set { set(newValue, forKey: UserDefaultsKeys.spectator) }
    }

    var disableInGameUI: Bool {
        get { return bool(forKey: UserDefaultsKeys.disableInGameUI) }
        set { set(newValue, forKey: UserDefaultsKeys.disableInGameUI) }
    }

    var synchronizeMusicWithWallClock: Bool {
        get { return bool(forKey: UserDefaultsKeys.synchronizeMusicWithWallClock) }
        set { set(newValue, forKey: UserDefaultsKeys.synchronizeMusicWithWallClock) }
    }
    
    var showThermalState: Bool {
        get { return bool(forKey: UserDefaultsKeys.showThermalState) }
        set { set(newValue, forKey: UserDefaultsKeys.showThermalState) }
    }
}
