/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`CallAction` represents an action to perform during a call.
*/

import Foundation

public struct CallAction: Codable {
    public enum Action: String, Codable {
        case connect
        case hangup
        case unavailable
    }
    
    public var action: Action
    public var receiver: User?
    
    public init(action: Action, receiver: User? = nil) {
        self.action = action
        self.receiver = receiver
    }
}
