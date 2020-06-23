/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Routing` represents the sender and intended receiver of a message.
*/

import Foundation

public struct Routing: Codable {
    public var sender: User
    public var receiver: User
    
    public init(sender: User, receiver: User) {
        self.sender = sender
        self.receiver = receiver
    }
}
