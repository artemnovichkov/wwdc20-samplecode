/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Conforms several types to CustomPlaygroundDisplayConvertible
*/

import Foundation
import NutritionFacts

extension NutritionFact: CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        description
    }
}
extension Measurement: CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.unitStyle = .long
        measurementFormatter.numberFormatter.maximumFractionDigits = 0
        return measurementFormatter.string(from: self)
    }
}
