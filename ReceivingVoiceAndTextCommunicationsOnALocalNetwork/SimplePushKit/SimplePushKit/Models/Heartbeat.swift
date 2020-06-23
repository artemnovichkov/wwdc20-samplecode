/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Heartbeat` represents a heartbeat.
*/

import Foundation

public struct Heartbeat: Codable {
    var count: Int64
    
    public init(count: Int64) {
        self.count = count
    }
}
