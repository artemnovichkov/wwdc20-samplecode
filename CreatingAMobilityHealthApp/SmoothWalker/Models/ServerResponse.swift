/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model used to represent an external server response.
*/

import Foundation

/// A representation of a server response which contains an array of weekly reports.
struct ServerResponse: Codable {
    let identifier: String
    var date: Date
    var weeklyReport: WeeklyReport
}

/// A representation of data summarizing data from a clinician.
struct WeeklyReport: Codable {
    let identifier: String
    var startDate: Date
    var endDate: Date
    var samples: [ServerHealthSample]
}

/// A representation of a health data sample..
struct ServerHealthSample: Codable {
    let syncIdentifier: String
    let syncVersion: Int
    let type: HealthSampleType
    let typeIdentifier: String
    let unit: String
    let value: Double
    var startDate: Date
    var endDate: Date
}

/// A description of the type of HKObjectType.
enum HealthSampleType: String, Codable {
    case category
    case quantity
}
