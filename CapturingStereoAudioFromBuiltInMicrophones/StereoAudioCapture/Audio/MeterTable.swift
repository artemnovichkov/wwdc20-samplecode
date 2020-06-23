/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An audio level meter lookup table.
*/

import Foundation

struct MeterTable {

    private let min_dB: Float = -60.0
    private let max_dB: Float = 0.0

    private let tableSize = 300

    private let scaleFactor: Float
    private var meterTable = [Float]()

    init() {
        let dbResolution = min_dB / Float(tableSize - 1)
        scaleFactor = 1.0 / dbResolution

        let minAmp = dbToAmp(dB: min_dB)
        let ampRange = 1.0 - minAmp
        let invAmpRange = 1.0 / ampRange

        for i in 0..<tableSize {
            let decibels = Float(i) * dbResolution
            let amp = dbToAmp(dB: decibels)
            let adjAmp = (amp - minAmp) * invAmpRange
            meterTable.append(adjAmp)
        }
   }

    private func dbToAmp(dB: Float) -> Float {
        return powf(10.0, 0.05 * dB)
    }

    func valueForPower(_ power: Float) -> Float {
        if power < min_dB {
            return 0.0
        } else if power >= 0.0 {
            return 1.0
        } else {
            let index = Int(power) * Int(scaleFactor)
            return meterTable[index]
        }
    }
}
