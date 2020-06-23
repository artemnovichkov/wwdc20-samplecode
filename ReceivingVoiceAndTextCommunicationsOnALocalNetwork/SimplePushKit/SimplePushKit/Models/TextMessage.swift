/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`TextMessage` represents a text based message sent from one user to another.
*/

import Foundation

public struct TextMessage: Codable, Routable {
    public var routing: Routing
    public var message: String
    
    public init(routing: Routing, message: String) {
        self.routing = routing
        self.message = message
    }
}
