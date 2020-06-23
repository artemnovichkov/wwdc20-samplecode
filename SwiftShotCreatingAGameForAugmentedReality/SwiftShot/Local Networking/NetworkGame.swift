/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Identifies a networked game session.
*/

import Foundation

struct NetworkGame: Hashable {
    var name: String
    var host: Player
    private var locationId: Int
    
    var location: GameTableLocation {
        return GameTableLocation.location(with: locationId)
    }

    init(host: Player, name: String? = nil, locationId: Int = 0) {
        self.host = host
        self.name = name ?? "\(host.username)'s Game"
        self.locationId = locationId
    }
}
