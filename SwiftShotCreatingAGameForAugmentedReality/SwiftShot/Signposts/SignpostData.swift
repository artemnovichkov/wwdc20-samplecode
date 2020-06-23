/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Performance debugging markers for use with os_signpost.
*/

import os.signpost

extension StaticString {
    // Signpost names for signposts related loading/starting a game
    static let preloadAssets = "PreloadAssets" as StaticString
    static let setupLevel = "SetupLevel" as StaticString

    // Signpost names for signposts related to scenekit render loop
    static let renderLoop = "RenderLoop" as StaticString
    static let logicUpdate = "GameLogicUpdate" as StaticString
    static let processCommand = "ProcessCommand" as StaticString
    static let physicsSync = "PhysicsSync" as StaticString
    static let postConstraintsUpdate = "PostConstraintsUpdate" as StaticString
    static let renderScene = "RenderScene" as StaticString

    // Signpost names for signposts related to networking
    static let networkActionSent = "NetworkActionSent" as StaticString
    static let networkActionReceived = "NetworkActionReceived" as StaticString
    static let networkPhysicsSent = "NetworkPhysicsSent" as StaticString
    static let networkPhysicsReceived = "NetworkPhysicsReceived" as StaticString
}

extension OSLog {
    // Custom log objects to use to classify signposts
    static let preloadAssets = OSLog(subsystem: "SwiftShot", category: "Preload")
    static let setupLevel = OSLog(subsystem: "SwiftShot", category: "LevelSetup")
    static let renderLoop = OSLog(subsystem: "SwiftShot", category: "RenderLoop")
    static let networkDataSent = OSLog(subsystem: "SwiftShot", category: "NetworkDataSent")
    static let networkDataReceived = OSLog(subsystem: "SwiftShot", category: "NetworkDataReceived")
}

extension OSSignpostID {
    // Custom signpost ids for signposts. Same id can be used for signposts that aren't concurrent with each other
    // Signpost ids for signposts related loading/starting a game
    static let preloadAssets = OSSignpostID(log: .preloadAssets)
    static let setupLevel = OSSignpostID(log: .setupLevel)

    // Signpost ids for signposts related to scenekit render loop
    static let renderLoop = OSSignpostID(log: .renderLoop)

    // Signpost ids for signposts related to networking
    static let networkDataSent = OSSignpostID(log: .networkDataSent)
    static let networkDataReceived = OSSignpostID(log: .networkDataReceived)
}
