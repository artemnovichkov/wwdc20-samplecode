/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Routable` is a protocol for messages that can be routed from one user to another.
*/

import Foundation

public protocol Routable {
    var routing: Routing { get set }
}
