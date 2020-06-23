/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Top-level container for physics data sync between peers.
*/

import Foundation

struct PhysicsSyncData {
    var packetNumber: Int
    var nodeData: [PhysicsNodeData]
    var projectileData: [PhysicsNodeData]
    var soundData: [CollisionSoundData]
    
    static let packetNumberBits = 12 // 12 bits represents packetNumber reset every minute
    static let nodeCountBits = 9
    static let maxPacketNumber = Int(pow(2.0, Double(packetNumberBits)))
    static let halfMaxPacketNumber = maxPacketNumber / 2
}

extension PhysicsSyncData: BitStreamCodable {
    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendUInt32(UInt32(packetNumber), numberOfBits: PhysicsSyncData.packetNumberBits)
        
        let nodeCount = nodeData.count
        bitStream.appendUInt32(UInt32(nodeCount), numberOfBits: PhysicsSyncData.nodeCountBits)
        for node in nodeData {
            node.encode(to: &bitStream)
        }
        
        let projectileCount = projectileData.count
        bitStream.appendUInt32(UInt32(projectileCount), numberOfBits: PhysicsSyncData.nodeCountBits)
        for projectile in projectileData {
            projectile.encode(to: &bitStream)
        }
        
        let soundCount = soundData.count
        bitStream.appendUInt32(UInt32(soundCount), numberOfBits: PhysicsSyncData.nodeCountBits)
        for sound in soundData {
            sound.encode(to: &bitStream)
        }
    }

    init(from bitStream: inout ReadableBitStream) throws {
        packetNumber = Int(try bitStream.readUInt32(numberOfBits: PhysicsSyncData.packetNumberBits))
        
        let nodeCount = Int(try bitStream.readUInt32(numberOfBits: PhysicsSyncData.nodeCountBits))
        nodeData = []
        for _ in 0..<nodeCount {
            nodeData.append(try PhysicsNodeData(from: &bitStream))
        }
        
        let projectileCount = Int(try bitStream.readUInt32(numberOfBits: PhysicsSyncData.nodeCountBits))
        projectileData = []
        for _ in 0..<projectileCount {
            projectileData.append(try PhysicsNodeData(from: &bitStream))
        }
        
        let soundCount = Int(try bitStream.readUInt32(numberOfBits: PhysicsSyncData.nodeCountBits))
        soundData = []
        for _ in 0..<soundCount {
            soundData.append(try CollisionSoundData(from: &bitStream))
        }
    }
}
