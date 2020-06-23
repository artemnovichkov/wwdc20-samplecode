/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`KeyCoder` represents the mapping of message types to protocol keys.
*/

import Foundation

struct KeyCoder: KeyCodable {
    var keymap: [UInt8: Codable.Type] {
        [
            0: Invite.self,
            1: User.self,
            2: CallAction.self,
            3: TextMessage.self,
            4: Heartbeat.self,
            5: Directory.self
        ]
    }
}
