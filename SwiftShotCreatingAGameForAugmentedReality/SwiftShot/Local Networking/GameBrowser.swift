/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Finds games in progress on the local network.
*/

import Foundation
import MultipeerConnectivity
import os.log

struct SwiftShotGameService {
    static let playerService = "swiftshot-p"
    static let spectatorService = "swiftshot-s"
}

struct SwiftShotGameAttribute {
    static let name = "SwiftShotGameAttributeName"
    static let location = "LocationAttributeName"
    static let appIdentifier = "AppIdentifierAttributeName"
}

protocol GameBrowserDelegate: class {
    func gameBrowser(_ browser: GameBrowser, sawGames: [NetworkGame])
}

class GameBrowser: NSObject {
    private let myself: Player
    private let serviceBrowser: MCNearbyServiceBrowser
    weak var delegate: GameBrowserDelegate?

    fileprivate var games: Set<NetworkGame> = []
    
    init(myself: Player) {
        self.myself = myself
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myself.peerID, serviceType: SwiftShotGameService.playerService)
        super.init()
        self.serviceBrowser.delegate = self
    }

    func start() {
        os_log(.info, "looking for peers")
        serviceBrowser.startBrowsingForPeers()
    }

    func stop() {
        os_log(.info, "stopping the search for peers")
        serviceBrowser.stopBrowsingForPeers()
    }

    func join(game: NetworkGame) -> NetworkSession? {
        guard games.contains(game) else { return nil }
        let session = NetworkSession(myself: myself, asServer: false, location: game.location, host: game.host)
        serviceBrowser.invitePeer(game.host.peerID, to: session.session, withContext: nil, timeout: 30)
        return session
    }
}

/// - Tag: GameBrowser-MCNearbyServiceBrowserDelegate
extension GameBrowser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        os_log(.info, "found peer %@", peerID)
        guard peerID != myself.peerID else {
            os_log(.info, "found myself, ignoring")
            return
        }
        guard let appIdentifier = info?[SwiftShotGameAttribute.appIdentifier],
            appIdentifier == Bundle.main.appIdentifier else {
                os_log(.info, "peer appIdentifier %s doesn't match, ignoring", info?[SwiftShotGameAttribute.appIdentifier] ?? "(nil)")
                return
        }
        DispatchQueue.main.async {
            let player = Player(peerID: peerID)
            let gameName = info?[SwiftShotGameAttribute.name]
            
            let location: GameTableLocation?
            if let info = info,
                let locationIdString = info[SwiftShotGameAttribute.location],
                let locationId = Int(locationIdString) {
                location = GameTableLocation.location(with: locationId)
            } else {
                location = nil
            }
            let game = NetworkGame(host: player, name: gameName, locationId: location?.identifier ?? 0)
            self.games.insert(game)
            self.delegate?.gameBrowser(self, sawGames: Array(self.games))
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        os_log(.info, "lost peer id %@", peerID)
        DispatchQueue.main.async {
            self.games = self.games.filter { $0.host.peerID != peerID }
            self.delegate?.gameBrowser(self, sawGames: Array(self.games))
        }
    }
    
    func refresh() {
        delegate?.gameBrowser(self, sawGames: Array(games))
    }
}
