/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`User` represents an individual user of the application.
*/

import Foundation

public struct User: Codable, Equatable, Hashable, Identifiable {
    public var uuid: UUID
    public var deviceName: String
    
    public var id: UUID {
        uuid
    }
    
    public init(uuid: UUID, deviceName: String) {
        self.uuid = uuid
        self.deviceName = deviceName
    }
}
