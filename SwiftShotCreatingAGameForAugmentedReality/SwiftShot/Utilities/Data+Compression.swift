/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for using LZFSE compression on arbitrary Data.
*/

import Foundation
import Compression

struct CompressionError: Error {}

extension Data {
    // Always returns the compressed version of self, even if it's
    // bigger than self.
    func compressed() -> Data {
        guard !isEmpty else { return self }
        // very small amounts of data become larger when compressed;
        // setting a floor of 10 seems to accomodate that properly.
        var targetBufferSize = Swift.max(count / 8, 10)
        while true {
            var result = Data(count: targetBufferSize)
            let resultCount = compress(into: &result)
            if resultCount == 0 {
                targetBufferSize *= 2
                continue
            }
            return result.prefix(resultCount)
        }
    }

    private func compress(into dest: inout Data) -> Int {
        let destSize = dest.count
        let srcSize = count

        let resultSize = withUnsafeBytes { source in
            return dest.withUnsafeMutableBytes { dest in
                return encodeRawBuffer(dest, destSize, source, srcSize)
            }
        }
        return resultSize
    }

    func decompressed() throws -> Data {
        guard !isEmpty else { return self }
        var targetBufferSize = count * 8
        while true {
            var result = Data(count: targetBufferSize)
            let resultCount = decompress(into: &result)
            if resultCount == 0 { throw CompressionError() }
            if resultCount == targetBufferSize {
                targetBufferSize *= 2
                continue
            }
            return result.prefix(resultCount)
        }
    }

    private func decompress(into dest: inout Data) -> Int {
        let destSize = dest.count
        let srcSize = count
        let result = withUnsafeBytes { source in
            return dest.withUnsafeMutableBytes { dest in
                return decodeRawBuffer(dest, destSize, source, srcSize)
            }
        }
        return result
    }
        
    private func encodeRawBuffer(_ dest: UnsafeMutableRawBufferPointer, _ destSize: Int, _ source: UnsafeRawBufferPointer, _ srcSize: Int) -> Int {
        let destPtr = dest.baseAddress!.bindMemory(to: UInt8.self, capacity: destSize)
        let srcPtr = source.baseAddress!.bindMemory(to: UInt8.self, capacity: srcSize)
        return compression_encode_buffer(destPtr, destSize, srcPtr, srcSize, nil, COMPRESSION_LZFSE)
    }
    private func decodeRawBuffer(_ dest: UnsafeMutableRawBufferPointer, _ destSize: Int, _ source: UnsafeRawBufferPointer, _ srcSize: Int) -> Int {
        let destPtr = dest.baseAddress!.bindMemory(to: UInt8.self, capacity: destSize)
        let srcPtr = source.baseAddress!.bindMemory(to: UInt8.self, capacity: srcSize)
        return compression_decode_buffer(destPtr, destSize, srcPtr, srcSize, nil, COMPRESSION_LZFSE)
    }
}
