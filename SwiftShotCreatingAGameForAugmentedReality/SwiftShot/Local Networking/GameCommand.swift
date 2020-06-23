/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Representations for game events, related data, and their encoding.
*/

import Foundation
import simd

/// - Tag: GameCommand
struct GameCommand {
    var player: Player?
    var action: Action
}

extension SIMD3 where Scalar == Float {
    init(from bitStream: inout ReadableBitStream) throws {
        let x = try bitStream.readFloat()
        let y = try bitStream.readFloat()
        let z = try bitStream.readFloat()
        self.init(x, y, z)
    }

    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendFloat(x)
        bitStream.appendFloat(y)
        bitStream.appendFloat(z)
    }
}

extension SIMD4 where Scalar == Float {
    init(from bitStream: inout ReadableBitStream) throws {
        let x = try bitStream.readFloat()
        let y = try bitStream.readFloat()
        let z = try bitStream.readFloat()
        let w = try bitStream.readFloat()
        self.init(x, y, z, w)
    }

    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendFloat(x)
        bitStream.appendFloat(y)
        bitStream.appendFloat(z)
        bitStream.appendFloat(w)
    }
}

extension float4x4: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        self.init()
        self.columns.0 = try SIMD4<Float>(from: &bitStream)
        self.columns.1 = try SIMD4<Float>(from: &bitStream)
        self.columns.2 = try SIMD4<Float>(from: &bitStream)
        self.columns.3 = try SIMD4<Float>(from: &bitStream)
    }

    func encode(to bitStream: inout WritableBitStream) {
        columns.0.encode(to: &bitStream)
        columns.1.encode(to: &bitStream)
        columns.2.encode(to: &bitStream)
        columns.3.encode(to: &bitStream)
    }
}

extension String: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let data = try bitStream.readData()
        if let value = String(data: data, encoding: .utf8) {
            self = value
        } else {
            throw BitStreamError.encodingError
        }
    }

    func encode(to bitStream: inout WritableBitStream) throws {
        if let data = data(using: .utf8) {
            bitStream.append(data)
        } else {
            throw BitStreamError.encodingError
        }
    }
}

enum GameBoardLocation: BitStreamCodable {
    
    case worldMapData(Data)
    case manual

    enum CodingKey: UInt32, CaseIterable {
        case worldMapData
        case manual
    }

    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .worldMapData:
            let data = try bitStream.readData()
            self = .worldMapData(data)
        case .manual:
            self = .manual
        }
    }

    func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .worldMapData(let data):
            bitStream.appendEnum(CodingKey.worldMapData)
            bitStream.append(data)
        case .manual:
            bitStream.appendEnum(CodingKey.manual)
        }
    }
}

enum BoardSetupAction: BitStreamCodable {
    case requestBoardLocation
    
    case boardLocation(GameBoardLocation)

    enum CodingKey: UInt32, CaseIterable {
        case requestBoardLocation
        case boardLocation

    }
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .requestBoardLocation:
            self = .requestBoardLocation
        case .boardLocation:
            let location = try GameBoardLocation(from: &bitStream)
            self = .boardLocation(location)
        }
    }

    func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .requestBoardLocation:
            bitStream.appendEnum(CodingKey.requestBoardLocation)
        case .boardLocation(let location):
            bitStream.appendEnum(CodingKey.boardLocation)
            location.encode(to: &bitStream)
        }
    }
}

struct Ray {
    var position: SIMD3<Float>
    var direction: SIMD3<Float>
    static var zero: Ray { return Ray(position: SIMD3<Float>(), direction: SIMD3<Float>()) }
}

extension Ray: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        position = try SIMD3<Float>(from: &bitStream)
        direction = try SIMD3<Float>(from: &bitStream)
    }

    func encode(to bitStream: inout WritableBitStream) {
        position.encode(to: &bitStream)
        direction.encode(to: &bitStream)
    }
}

struct CameraInfo {
    var transform: float4x4
    var ray: Ray {
        let position = transform.translation
        let direction = normalize((transform * SIMD4<Float>(0, 0, -1, 0)).xyz)
        return Ray(position: position, direction: direction)
    }
}

extension CameraInfo: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        self.init(transform: try float4x4(from: &bitStream))
    }

    func encode(to bitStream: inout WritableBitStream) {
        transform.encode(to: &bitStream)
    }
}

// GameVelocity stores the origin and vector of velocity.
// It is similar to ray, but whereas ray will have normalized direction, the .vector is the velocity vector
struct GameVelocity {
    var origin: SIMD3<Float>
    var vector: SIMD3<Float>
    static var zero: GameVelocity { return GameVelocity(origin: SIMD3<Float>(), vector: SIMD3<Float>()) }
}

extension GameVelocity: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        origin = try SIMD3<Float>(from: &bitStream)
        vector = try SIMD3<Float>(from: &bitStream)
    }

    func encode(to bitStream: inout WritableBitStream) {
        origin.encode(to: &bitStream)
        vector.encode(to: &bitStream)
    }
}

extension InteractionState: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let rawValue = Int(try bitStream.readUInt32(numberOfBits: 2))
        if let value = InteractionState(rawValue: rawValue) {
            self = value
        } else {
            throw BitStreamError.encodingError
        }
    }

    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendUInt32(UInt32(rawValue), numberOfBits: 2)
    }
}

// when a catapult is knocked down
struct HitCatapult {
    var catapultID: Int
    var justKnockedout: Bool
    var vortex: Bool
}

extension HitCatapult: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        catapultID = Int(try bitStream.readUInt32(numberOfBits: 4))
        justKnockedout = try bitStream.readBool()
        vortex = try bitStream.readBool()
    }

    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendUInt32(UInt32(catapultID), numberOfBits: 4)
        bitStream.appendBool(justKnockedout)
        bitStream.appendBool(vortex)
    }
}

extension ProjectileType: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        self = try bitStream.readEnum()
    }

    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendEnum(self)
    }
}

struct SlingData {
    var catapultID: Int
    var projectileType: ProjectileType
    var velocity: GameVelocity
}

extension SlingData: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        catapultID = Int(try bitStream.readUInt32(numberOfBits: 4))
        projectileType = try ProjectileType(from: &bitStream)
        velocity = try GameVelocity(from: &bitStream)
    }

    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendUInt32(UInt32(catapultID), numberOfBits: 4)
        projectileType.encode(to: &bitStream)
        velocity.encode(to: &bitStream)
    }
}

struct GrabInfo {
    var grabbableID: Int?
    var cameraInfo: CameraInfo
}

extension GrabInfo: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let hasId = try bitStream.readBool()
        if hasId {
            grabbableID = Int(try bitStream.readUInt32(numberOfBits: 4))
        } else {
            grabbableID = nil
        }
        cameraInfo = try CameraInfo(from: &bitStream)
    }

    func encode(to bitStream: inout WritableBitStream) {
        if let catapult = grabbableID {
            bitStream.appendBool(true)
            bitStream.appendUInt32(UInt32(catapult), numberOfBits: 4)
        } else {
            bitStream.appendBool(false)
        }
        cameraInfo.encode(to: &bitStream)
    }
}

struct LeverMove {
    var leverID: Int
    var eulerAngleX: Float
}

extension LeverMove: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        leverID = Int(try bitStream.readUInt32(numberOfBits: 3))
        eulerAngleX = try bitStream.readFloat()
    }

    func encode(to bitStream: inout WritableBitStream) throws {
        bitStream.appendUInt32(UInt32(leverID), numberOfBits: 3)
        bitStream.appendFloat(eulerAngleX)
    }
}

/// - Tag: GameAction
enum GameAction {
    case oneHitKOPrepareAnimation
    
    case tryGrab(GrabInfo)
    case grabStart(GrabInfo)
    case grabMove(GrabInfo)
    case tryRelease(GrabInfo)
    case releaseEnd(GrabInfo)
    
    case catapultRelease(SlingData)
    case grabbableStatus(GrabInfo)
    
    case requestKnockoutSync
    case catapultKnockOut(HitCatapult)
    case leverMove(LeverMove)

    case physics(PhysicsSyncData)

    private enum CodingKey: UInt32, CaseIterable {
        case oneHitKOAnimate
        
        case tryGrab
        case grabStart
        case grabMove
        case tryRelease
        case releaseEnd
        
        case catapultRelease
        case grabbableStatus
        case knockoutSync
        case hitCatapult
        case leverMove

        case physicsSyncData
    }
}

extension GameAction: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .oneHitKOAnimate:
            self = .oneHitKOPrepareAnimation
            
        case .tryGrab:
            let data = try GrabInfo(from: &bitStream)
            self = .tryGrab(data)
        case .grabStart:
            let data = try GrabInfo(from: &bitStream)
            self = .grabStart(data)
        case .grabMove:
            let data = try GrabInfo(from: &bitStream)
            self = .grabMove(data)
        case .tryRelease:
            let data = try GrabInfo(from: &bitStream)
            self = .tryRelease(data)
        case .releaseEnd:
            let data = try GrabInfo(from: &bitStream)
            self = .releaseEnd(data)
            
        case .catapultRelease:
            let data = try SlingData(from: &bitStream)
            self = .catapultRelease(data)
        case .grabbableStatus:
            let data = try GrabInfo(from: &bitStream)
            self = .grabbableStatus(data)
        case .knockoutSync:
            self = .requestKnockoutSync
        case .hitCatapult:
            let data = try HitCatapult(from: &bitStream)
            self = .catapultKnockOut(data)
        case .leverMove:
            let data = try LeverMove(from: &bitStream)
            self = .leverMove(data)

        case .physicsSyncData:
            let data = try PhysicsSyncData(from: &bitStream)
            self = .physics(data)
        }
    }

    func encode(to bitStream: inout WritableBitStream) throws {
        switch self {
        case .oneHitKOPrepareAnimation:
            bitStream.appendEnum(CodingKey.oneHitKOAnimate)
        case .tryGrab(let data):
            bitStream.appendEnum(CodingKey.tryGrab)
            data.encode(to: &bitStream)
        case .grabStart(let data):
            bitStream.appendEnum(CodingKey.grabStart)
            data.encode(to: &bitStream)
        case .grabMove(let data):
            bitStream.appendEnum(CodingKey.grabMove)
            data.encode(to: &bitStream)
        case .tryRelease(let data):
            bitStream.appendEnum(CodingKey.tryRelease)
            data.encode(to: &bitStream)
        case .releaseEnd(let data):
            bitStream.appendEnum(CodingKey.releaseEnd)
            data.encode(to: &bitStream)
        case .catapultRelease(let data):
            bitStream.appendEnum(CodingKey.catapultRelease)
            data.encode(to: &bitStream)
        case .grabbableStatus(let data):
            bitStream.appendEnum(CodingKey.grabbableStatus)
            data.encode(to: &bitStream)
        case .requestKnockoutSync:
            bitStream.appendEnum(CodingKey.knockoutSync)
        case .catapultKnockOut(let coords):
            bitStream.appendEnum(CodingKey.hitCatapult)
            coords.encode(to: &bitStream)
        case .leverMove(let data):
            bitStream.appendEnum(CodingKey.leverMove)
            try data.encode(to: &bitStream)
        case .physics(let data):
            bitStream.appendEnum(CodingKey.physicsSyncData)
            data.encode(to: &bitStream)
        }
    }
}

struct StartGameMusicTime {
    let startNow: Bool
    let timestamps: [TimeInterval]

    let countBits = 4
    let maxCount = 1 << 4

    init(startNow: Bool, timestamps: [TimeInterval]) {
        self.startNow = startNow
        self.timestamps = timestamps
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        self.startNow = try bitStream.readBool()
        let count = try bitStream.readUInt32(numberOfBits: countBits)
        var timestamps = [TimeInterval]()
        for _ in 0..<count {
            let milliseconds = try bitStream.readUInt32()
            timestamps.append(TimeInterval(Double(milliseconds) / 1000.0))
        }
        self.timestamps = timestamps
    }

    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendBool(startNow)
        guard timestamps.count < maxCount else {
            fatalError("Cannot encode more than \(maxCount) timestamps")
        }
        bitStream.appendUInt32(UInt32(timestamps.count), numberOfBits: countBits)
        for timestamp in timestamps {
            bitStream.appendUInt32(UInt32(timestamp * 1000.0))
        }
    }
}

extension StartGameMusicTime: CustomDebugStringConvertible {
    var debugDescription: String {
        return "<StartGameMusicTime startNow=\(startNow) times=\(timestamps)>"
    }
}

enum Action {
    
    case gameAction(GameAction)
    case boardSetup(BoardSetupAction)
    case startGameMusic(StartGameMusicTime)
}

extension Action: BitStreamCodable {
    private enum CodingKey: UInt32, CaseIterable {
        case gameAction
        case boardSetup
        case startGameMusic
    }

    func encode(to bitStream: inout WritableBitStream) throws {
        switch self {
        case .gameAction(let gameAction):
            bitStream.appendEnum(CodingKey.gameAction)
            try gameAction.encode(to: &bitStream)
        case .boardSetup(let boardSetup):
            bitStream.appendEnum(CodingKey.boardSetup)
            boardSetup.encode(to: &bitStream)
        case .startGameMusic(let timeData):
            bitStream.appendEnum(CodingKey.startGameMusic)
            timeData.encode(to: &bitStream)
        }
    }

    init(from bitStream: inout ReadableBitStream) throws {
        let code: CodingKey = try bitStream.readEnum()
        switch code {
        case .gameAction:
            let gameAction = try GameAction(from: &bitStream)
            self = .gameAction(gameAction)
        case .boardSetup:
            let boardAction = try BoardSetupAction(from: &bitStream)
            self = .boardSetup(boardAction)
        case .startGameMusic:
            let timeData = try StartGameMusicTime(from: &bitStream)
            self = .startGameMusic(timeData)
        }
    }
}
