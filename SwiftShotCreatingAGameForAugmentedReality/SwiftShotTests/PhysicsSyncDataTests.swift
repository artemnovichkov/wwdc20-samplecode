/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Test cases for PhysicsSync.
*/

import XCTest
import simd

@testable import SwiftShot

class PhysicsSyncDataTests: XCTestCase {

    func roundTrip<T>(_ input: T) throws -> T where T: BitStreamCodable {
        var writeStream = WritableBitStream()
        try input.encode(to: &writeStream)
        let data = writeStream.packData()

        var readStream = ReadableBitStream(data: data)
        let result = try T(from: &readStream)
        return result
    }

    func testNodeData() throws {
        var nodeData = PhysicsNodeData()
        nodeData.isMoving = true
        nodeData.orientation = simd_quatf(ix: 1, iy: 1, iz: 1, r: 2)
        nodeData.team = .teamA

        let newData = try roundTrip(nodeData)

        XCTAssertEqual(nodeData.isMoving, newData.isMoving)
        XCTAssertEqual(nodeData.team, newData.team)
    }

    func testPhysicsPacket() throws {
        var nodeData = PhysicsNodeData()
        nodeData.isMoving = true
        nodeData.isAlive = true
        nodeData.orientation = simd_quatf(ix: 1, iy: 1, iz: 1, r: 2)

        let nodes = [PhysicsNodeData](repeating: nodeData, count: 154)

        var poolData = nodeData
        poolData.team = .teamB
        let pools = [PhysicsNodeData](repeating: poolData, count: 30)

        let packet = PhysicsSyncData(packetNumber: 0, nodeData: nodes, projectileData: pools, soundData: [])
        let action = GameAction.physics(packet)

        var writeStream = WritableBitStream()
        try action.encode(to: &writeStream)
        let data = writeStream.packData()

        var readStream = ReadableBitStream(data: data)
        let newAction = try GameAction(from: &readStream)

        if case .physics(let newPacket) = newAction {
            XCTAssertEqual(packet.nodeData.count, newPacket.nodeData.count)
            XCTAssertEqual(packet.projectileData.count, newPacket.projectileData.count)
        } else {
            XCTFail("wrong thing")
        }
    }
}
