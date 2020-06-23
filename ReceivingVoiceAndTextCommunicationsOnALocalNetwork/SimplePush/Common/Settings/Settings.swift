/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model that describes the application's settings.
*/

import Foundation
import SimplePushKit

public struct Settings: Equatable, Codable {
    var uuid: UUID
    var deviceName: String
    var ssid: String
    var host: String
}

extension Settings {
    var user: User {
        User(uuid: uuid, deviceName: deviceName)
    }
}
