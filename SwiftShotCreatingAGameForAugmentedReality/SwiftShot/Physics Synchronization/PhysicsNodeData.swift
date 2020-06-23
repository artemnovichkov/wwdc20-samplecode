/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Synchronization for node-specific physics data.
*/

import Foundation
import simd
import SceneKit

private let positionCompressor = FloatCompressor(minValue: -80.0, maxValue: 80.0, bits: 16)
private let orientationCompressor: FloatCompressor = {
    let range: Float = 1.0 / sqrt(2)
    return FloatCompressor(minValue: -range, maxValue: range, bits: 12)
}()

// From testing, velocity magnitude rarely go above ~50
private let velocityCompressor = FloatCompressor(minValue: -200.0, maxValue: 200.0, bits: 16)

// From testing, angularVelocity magnitude rarely go above ~100.0
private let angularVelocityMagnitudeCompressor = FloatCompressor(minValue: -200.0, maxValue: 200.0, bits: 16)
private let angularVelocityAxisCompressor = FloatCompressor(minValue: -1.0, maxValue: 1.0, bits: 12)

// Below these delta values, node's linear/angular velocity will not sync across
private let positionDeltaToConsiderNotMoving: Float = 0.0002
private let orientationDeltaToConsiderNotMoving: Float = 0.002

/// - Tag: PhysicsNodeData
struct PhysicsNodeData: CustomStringConvertible {
    var isAlive = true
    var isMoving = false
    var team = Team.none
    var position = SIMD3<Float>()
    var orientation = simd_quatf()
    var velocity = SIMD3<Float>()
    var angularVelocity = SIMD4<Float>()
    
    var description: String {
        let pos = position
        let rot = orientation.vector
        return "isMoving:\(isMoving), pos:\(pos.x),\(pos.y),\(pos.z), rot:\(rot.x),\(rot.y),\(rot.z),\(rot.w)"
    }
}

extension PhysicsNodeData {
    init(node: SCNNode, alive: Bool, team: Team = .none) {
        isAlive = alive
        self.team = team
        let newPosition = node.presentation.simdWorldPosition
        let newOrientation = node.presentation.simdOrientation

        position = newPosition
        orientation = newOrientation

        if let physicsBody = node.physicsBody {
            // Do not sync across physicsBodies
            isMoving = !newPosition.almostEqual(position, within: positionDeltaToConsiderNotMoving) ||
                !newOrientation.vector.almostEqual(orientation.vector, within: orientationDeltaToConsiderNotMoving)
            
            if isMoving {
                velocity = physicsBody.simdVelocity
                angularVelocity = physicsBody.simdAngularVelocity
            } else {
                velocity = SIMD3<Float>()
                angularVelocity = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
            }
        }
    }
}

extension PhysicsNodeData: BitStreamCodable {
    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendBool(isAlive)
        if !isAlive { return }
        bitStream.appendBool(isMoving)
        team.encode(to: &bitStream)

        // Position
        positionCompressor.write(position, to: &bitStream)

        // Orientation: send 2 bits specifying the max component, send 3 compressed float for the 3 smallest components
        var vector = orientation.vector
        var maxComponent = abs(vector[0]) > abs(vector[1]) ? 0 : 1
        maxComponent = abs(vector[2]) > abs(vector[maxComponent]) ? 2 : maxComponent
        maxComponent = abs(vector[3]) > abs(vector[maxComponent]) ? 3 : maxComponent
        bitStream.appendUInt32(UInt32(maxComponent), numberOfBits: 2)

        // flip the quaternion sign if the max component is negative, this is to avoid having to send over another
        // bit to specify if the max component is negative.
        // negative quaternion has the same behavior as positive quaternion
        if vector[maxComponent] < 0 {
            vector = -vector
        }

        for index in 0..<4 where index != maxComponent {
            orientationCompressor.write(vector[index], to: &bitStream)
        }

        // Moving Case:
        guard isMoving else { return }

        velocityCompressor.write(velocity, to: &bitStream)

        // AngularVelocity will have NaN if it was not set
        // In this case sync over zero vector
        var angularVelocityToSend = angularVelocity
        if angularVelocityToSend.hasNaN {
            angularVelocityToSend = SIMD4<Float>(0.0, 0.0, 0.0, 0.0)
        }

        // Make sure angular velocity axis is normalized so that it will not exceed compressedFloat limit
        angularVelocityToSend.xyz = normalize(angularVelocityToSend.xyz)

        angularVelocityAxisCompressor.write(angularVelocityToSend.xyz, to: &bitStream)
        angularVelocityMagnitudeCompressor.write(angularVelocityToSend.w, to: &bitStream)
    }

    init(from bitStream: inout ReadableBitStream) throws {
        isAlive = try bitStream.readBool()
        if !isAlive { return }
        isMoving = try bitStream.readBool()
        team = try Team(from: &bitStream)
        // Position
        position = try positionCompressor.readSIMD3Float(from: &bitStream)

        // Orientation: use quaternion to
        let maxComponent = Int(try bitStream.readUInt32(numberOfBits: 2))

        var orientationVector = SIMD4<Float>()
        var squareSum: Float = 0.0
        for index in 0..<4 where index != maxComponent {
            orientationVector[index] = try orientationCompressor.read(from: &bitStream)
            squareSum += orientationVector[index] * orientationVector[index]
        }
        orientationVector[maxComponent] = sqrtf(1.0 - squareSum)
        orientation = simd_quatf(vector: orientationVector)

        // Moving Case:
        guard isMoving else { return }

        velocity = try velocityCompressor.readSIMD3Float(from: &bitStream)

        let angularVelocityAxis = try angularVelocityAxisCompressor.readSIMD3Float(from: &bitStream)
        let angularVelocityMagnitude = try angularVelocityMagnitudeCompressor.read(from: &bitStream)

        let angularVelocityReceived = SIMD4<Float>(angularVelocityAxis.x, angularVelocityAxis.y, angularVelocityAxis.z, angularVelocityMagnitude)

        // Zero vector angularVelocity means it is NaN, and we can ignore the update
        if angularVelocityReceived != .zero {
            angularVelocity = angularVelocityReceived
        }
    }
}
