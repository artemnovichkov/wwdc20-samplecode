/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Invite` represents a user's intent to initiate a call with a recipient.
*/

import Foundation

public struct Invite: Codable, Routable {
    public var routing: Routing
    
    public init(routing: Routing) {
        self.routing = routing
    }
}
