/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model used to describe a health data value.
*/

import Foundation

/// A representation of health data to use for `HealthDataTypeTableViewController`.
struct HealthDataTypeValue {
    let startDate: Date
    let endDate: Date
    var value: Double
}
