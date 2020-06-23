/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Test cases for GameAction.
*/

import XCTest
import SceneKit

@testable import SwiftShot

class GameActionTests: XCTestCase {

    func messageSizeTest(_ action: Action) throws {
        var bitStream = WritableBitStream()
        try action.encode(to: &bitStream)
        let data = bitStream.packData()
        print("result length \(data.count)")
    }

    func testMessageSize() throws {
        let gameAction = GameAction.leverMove(LeverMove(leverID: 3, eulerAngleX: 3.2))
        let action = Action.gameAction(gameAction)

        try messageSizeTest(action)
    }

    func testDataMessageSize() throws {
        let data = Data(count: 1000)
        let action = Action.boardSetup(.boardLocation(.worldMapData(data)))

        try messageSizeTest(action)
    }

    func testEncoding() {
        let action = GameAction.leverMove(LeverMove(leverID: 3, eulerAngleX: 3.2))

        measure {
            for _ in 0..<10_000 {
                var bitStream = WritableBitStream()
                try? action.encode(to: &bitStream)
            }
        }
    }

    func testDecoding() throws {
        let action = GameAction.leverMove(LeverMove(leverID: 3, eulerAngleX: 3.2))

        var writableString = WritableBitStream()
        try action.encode(to: &writableString)
        let data = writableString.packData()
        print("result length \(data.count)")

        measure {
            for _ in 0..<10_000 {
                var readableString = ReadableBitStream(data: data)
                _ = try! GameAction(from: &readableString)
            }
        }
    }

    func testStartGameMusicTime() throws {
        let timeData = StartGameMusicTime(startNow: true, timestamps: [1, 2, 3])
        var writableString = WritableBitStream()
        timeData.encode(to: &writableString)
        let data = writableString.packData()

        var readableString = ReadableBitStream(data: data)
        let result = try StartGameMusicTime(from: &readableString)
        XCTAssertEqual(timeData.startNow, result.startNow)
        XCTAssertEqual(timeData.timestamps, result.timestamps)
    }
}
