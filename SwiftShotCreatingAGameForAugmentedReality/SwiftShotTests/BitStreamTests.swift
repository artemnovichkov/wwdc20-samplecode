/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Test cases for BitStream.
*/

import XCTest

@testable import SwiftShot

class BitStreamTests: XCTestCase {

    func testEncodingDecoding() throws {
        var bitStream = WritableBitStream()
        bitStream.appendBool(false)
        bitStream.appendUInt32(12_345_678)
        bitStream.appendFloat(88.88)
        bitStream.appendUInt32(123, numberOfBits: 10)
        
        let compressor = FloatCompressor(minValue: -1.0, maxValue: 1.0, bits: 12)

        compressor.write(0.88, to: &bitStream)
        let data = bitStream.packData()
        
        var readableString = ReadableBitStream(data: data)
        XCTAssertEqual(false, try readableString.readBool())
        XCTAssertEqual(12_345_678, try readableString.readUInt32())
        XCTAssertEqual(88.88, try readableString.readFloat())
        XCTAssertEqual(123, try readableString.readUInt32(numberOfBits: 10))

        let float = try compressor.read(from: &readableString)
        XCTAssertEqual(0.88, float, accuracy: 0.001)
        XCTAssert(readableString.isAtEnd)
    }

    func testFloatCompression() throws {
        var bitStream = WritableBitStream()

        let compressor = FloatCompressor(minValue: 0.0, maxValue: 1.0, bits: 8)
        compressor.write(0, to: &bitStream)
        compressor.write(1, to: &bitStream)
        compressor.write(0.5, to: &bitStream)

        let data = bitStream.packData()
        XCTAssertEqual(data.count, 7) // 3 bytes + 4 bytes header
        var readableString = ReadableBitStream(data: data)
        let first = try compressor.read(from: &readableString)
        XCTAssertEqual(first, 0.0, accuracy: 0.002)
        let second = try compressor.read(from: &readableString)
        XCTAssertEqual(second, 1.0, accuracy: 0.002)
        let third = try compressor.read(from: &readableString)
        XCTAssertEqual(third, 0.5, accuracy: 0.002)
        XCTAssert(readableString.isAtEnd)
    }

    func testDataEncoding() throws {
        var bitStream = WritableBitStream()

        bitStream.appendBool(true)
        bitStream.appendBool(false)
        bitStream.appendBool(false)
        let data = Data(repeating: 0xff, count: 37)
        bitStream.append(data)

        let packed = bitStream.packData()

        var readString = ReadableBitStream(data: packed)
        XCTAssertEqual(true, try readString.readBool())
        XCTAssertEqual(false, try readString.readBool())
        XCTAssertEqual(false, try readString.readBool())
        XCTAssertEqual(data, try readString.readData())
    }

    func testNodeCounts() throws {
        let code: UInt32 = 2
        let count: UInt32 = 154

        var bitStream = WritableBitStream()
        bitStream.appendUInt32(code, numberOfBits: 2)
        bitStream.appendUInt32(count, numberOfBits: 9)
        let packed = bitStream.packData()

        var readString = ReadableBitStream(data: packed)
        XCTAssertEqual(code, try readString.readUInt32(numberOfBits: 2))
        XCTAssertEqual(count, try readString.readUInt32(numberOfBits: 9))
    }
}
