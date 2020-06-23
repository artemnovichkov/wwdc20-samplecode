/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Test cases for Data compression.
*/

import XCTest
@testable import SwiftShot

class DataCompressionTests: XCTestCase {

    func roundTrip(input: Data) throws {
        let compressed = input.compressed()
        let output = try compressed.decompressed()
        XCTAssertEqual(input, output)
    }

    func testCompression() throws {
        let input = Data(repeating: 12, count: 10_000)

        try roundTrip(input: input)
    }

    func testTinyCompression() throws {
        let input = Data(repeating: 4, count: 1)
        try roundTrip(input: input)
    }

    func testEmpty() throws {
        let input = Data()
        try roundTrip(input: input)
    }
}
