/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Test cases for BitStreamCodable.
*/

import XCTest

@testable import SwiftShot

struct Thing: Codable, Equatable {
    var num: Int
    var name: String
    var data: Data
}

extension Thing: BitStreamCodable {}

class BitStreamCodableTests: XCTestCase {

    func testBitStreamCodableDefaultImplementations() throws {
        let input = Thing(num: 87, name: "This is a thing.", data: Data(repeating: 0x6f, count: 123))
        var bitStream = WritableBitStream()
        try input.encode(to: &bitStream)

        let packedData = bitStream.packData()

        var readableString = ReadableBitStream(data: packedData)

        let output = try Thing(from: &readableString)

        XCTAssertEqual(input, output)
    }
}
