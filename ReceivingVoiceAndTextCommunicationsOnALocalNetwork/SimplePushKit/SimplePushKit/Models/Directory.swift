/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Directory` represents the list of connected users.
*/

import Foundation

public struct Directory: Codable {
    public var users: [User]
    
    public init(users: [User]) {
        self.users = users
    }
}
