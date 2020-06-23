/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Synchronization for sound-related physics data.
*/

import Foundation
import SceneKit

private let modWheelCompressor = FloatCompressor(minValue: 0.0, maxValue: 1.0, bits: 7)

struct CollisionSoundData {
    var gameObjectIndex: Int
    var soundEvent: CollisionAudioSampler.CollisionEvent
}

extension CollisionSoundData: BitStreamCodable {
    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendUInt32(UInt32(gameObjectIndex), numberOfBits: 9)
        bitStream.appendUInt32(UInt32(soundEvent.note), numberOfBits: 7)
        bitStream.appendUInt32(UInt32(soundEvent.velocity), numberOfBits: 7)
        modWheelCompressor.write(soundEvent.modWheel, to: &bitStream)
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        gameObjectIndex = Int(try bitStream.readUInt32(numberOfBits: 9))
        let note = UInt8(try bitStream.readUInt32(numberOfBits: 7))
        let velocity = UInt8(try bitStream.readUInt32(numberOfBits: 7))
        let modWheel = try modWheelCompressor.read(from: &bitStream)
        soundEvent = CollisionAudioSampler.CollisionEvent(note: note, velocity: velocity, modWheel: modWheel)
    }
}
