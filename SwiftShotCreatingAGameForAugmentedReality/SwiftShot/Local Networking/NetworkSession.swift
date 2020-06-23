/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages the multipeer networking for a game.
*/

import Foundation
import MultipeerConnectivity
import simd
import os.signpost

protocol NetworkSessionDelegate: class {
    func networkSession(_ session: NetworkSession, received command: GameCommand)
    func networkSession(_ session: NetworkSession, joining player: Player)
    func networkSession(_ session: NetworkSession, leaving player: Player)
}

// kMCSessionMaximumNumberOfPeers is the maximum number in a session; because we only track
// others and not ourself, decrement the constant for our purposes.
private let maxPeers = kMCSessionMaximumNumberOfPeers - 1

/// - Tag: NetworkSession
class NetworkSession: NSObject {

    let myself: Player
    private var peers: Set<Player> = []

    let isServer: Bool
    let session: MCSession
    var location: GameTableLocation?
    let host: Player
    let appIdentifier: String

    weak var delegate: NetworkSessionDelegate?

    private var serviceAdvertiser: MCNearbyServiceAdvertiser?

    init(myself: Player, asServer: Bool, location: GameTableLocation?, host: Player) {
        self.myself = myself
        self.session = MCSession(peer: myself.peerID, securityIdentity: nil, encryptionPreference: .required)
        self.isServer = asServer
        self.location = location
        self.host = host
        // if the appIdentifier is missing from the main bundle, that's
        // a significant build error and we should crash.
        self.appIdentifier = Bundle.main.appIdentifier!
        os_log("my appIdentifier is %s", self.appIdentifier)
        super.init()
        self.session.delegate = self
    }

    // for use when acting as game server
    func startAdvertising() {
        guard serviceAdvertiser == nil else { return } // already advertising

        os_log(.info, "ADVERTISING %@", myself.peerID)
        var discoveryInfo: [String: String] = [SwiftShotGameAttribute.appIdentifier: appIdentifier]
        if let location = location {
            discoveryInfo[SwiftShotGameAttribute.location] = String(location.identifier)
        }
        let advertiser = MCNearbyServiceAdvertiser(peer: myself.peerID,
                                                   discoveryInfo: discoveryInfo,
                                                   serviceType: SwiftShotGameService.playerService)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        serviceAdvertiser = advertiser
    }

    func stopAdvertising() {
        os_log(.info, "stop advertising")
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceAdvertiser = nil
    }

    // for beacon use
    func updateLocation(newLocation: GameTableLocation) {
        location = newLocation
    }

    // MARK: Actions
    func send(action: Action) {
        guard !peers.isEmpty else { return }
        do {
            var bits = WritableBitStream()
            try action.encode(to: &bits)
            let data = bits.packData()
            let peerIds = peers.map { $0.peerID }
            try session.send(data, toPeers: peerIds, with: .reliable)
            if action.description != "physics" {
                 os_signpost(.event, log: .networkDataSent, name: .networkActionSent, signpostID: .networkDataSent,
                             "Action : %s", action.description)
            } else {
                let bytes = Int32(exactly: data.count) ?? Int32.max
                os_signpost(.event, log: .networkDataSent, name: .networkPhysicsSent, signpostID: .networkDataSent,
                            "%d Bytes Sent", bytes)
            }
        } catch {
            os_log(.error, "sending failed: %s", "\(error)")
        }
    }

    func send(action: Action, to player: Player) {
        do {
            var bits = WritableBitStream()
            try action.encode(to: &bits)
            let data = bits.packData()
            if data.count > 10_000 {
                try sendLarge(data: data, to: player.peerID)
            } else {
                try sendSmall(data: data, to: player.peerID)
            }
            if action.description != "physics" {
                os_signpost(.event, log: .networkDataSent, name: .networkActionSent, signpostID: .networkDataSent,
                            "Action : %s", action.description)
            } else {
                let bytes = Int32(exactly: data.count) ?? Int32.max
                os_signpost(.event, log: .networkDataSent, name: .networkPhysicsSent, signpostID: .networkDataSent,
                            "%d Bytes Sent", bytes)
            }
        } catch {
            os_log(.error, "sending failed: %s", "\(error)")
        }
    }

    func sendSmall(data: Data, to peer: MCPeerID) throws {
        try session.send(data, toPeers: [peer], with: .reliable)
    }

    func sendLarge(data: Data, to peer: MCPeerID) throws {
        let fileName = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try data.write(to: fileName)
        session.sendResource(at: fileName, withName: "Action", toPeer: peer) { error in
            if let error = error {
                os_log(.error, "sending failed: %s", "\(error)")
                return
            }
            os_log(.info, "send succeeded, removing temp file")
            do {
                try FileManager.default.removeItem(at: fileName)
            } catch {
                os_log(.error, "removing failed: %s", "\(error)")
            }
        }
    }

    func receive(data: Data, from peerID: MCPeerID) {
        guard let player = peers.first(where: { $0.peerID == peerID }) else {
            os_log(.info, "peer %@ unknown!", peerID)
            return
        }
        do {
            var bits = ReadableBitStream(data: data)
            let action = try Action(from: &bits)
            let command = GameCommand(player: player, action: action)
            delegate?.networkSession(self, received: command)
            if action.description != "physics" {
                os_signpost(.event, log: .networkDataReceived, name: .networkActionReceived, signpostID: .networkDataReceived,
                            "Action : %s", action.description)
            } else {
                let peerID = Int32(truncatingIfNeeded: peerID.displayName.hashValue)
                let bytes = Int32(exactly: data.count) ?? Int32.max
                os_signpost(.event, log: .networkDataReceived, name: .networkPhysicsReceived, signpostID: .networkDataReceived,
                            "%d Bytes Sent from %d", bytes, peerID)
            }
        } catch {
            os_log(.error, "deserialization error: %s", "\(error)")
        }
    }
}

/// - Tag: NetworkSession-MCSessionDelegate
extension NetworkSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        os_log(.info, "peer %@ state is now %d", peerID, state.rawValue)
        let player = Player(peerID: peerID)
        switch state {
        case .connected:
            peers.insert(player)
            delegate?.networkSession(self, joining: player)
        case .connecting:
            break
        case.notConnected:
            peers.remove(player)
            delegate?.networkSession(self, leaving: player)
        default:
            fatalError(#function + " - Unexpected multipeer connectivity state.")
        }
        // on the server, check to see if we're at the max number of players
        guard isServer else { return }
        if peers.count >= maxPeers {
            stopAdvertising()
        } else {
            startAdvertising()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        receive(data: data, from: peerID)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        os_log(.info, "peer %@ sent a stream named %s", peerID, streamName)
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        os_log(.info, "peer %@ started sending a resource named %s", peerID, resourceName)
    }

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        os_log(.info, "peer %@ finished sending a resource named %s", peerID, resourceName)
        if let error = error {
            os_log(.error, "failed to receive resource: %s", "\(error)")
            return
        }
        guard let url = localURL else { os_log(.error, "what what no url?"); return }

        do {
            // .mappedIfSafe makes the initializer attempt to map the file directly into memory
            // using mmap(2), rather than serially copying the bytes into memory.
            // this is faster and our app isn't charged for the memory usage.
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            receive(data: data, from: peerID)
            // removing the file is done by the session, so long as we're done with it before the
            // delegate method returns.
        } catch {
            os_log(.error, "dealing with resource failed: %s", "\(error)")
        }
    }
}

extension NetworkSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if peers.count >= maxPeers {
            os_log(.error, "game full, refusing connection from %@", peerID)
            invitationHandler(false, nil)
        } else {
            os_log(.info, "accepting request from %@", peerID)
            invitationHandler(true, session)
        }
    }
}
