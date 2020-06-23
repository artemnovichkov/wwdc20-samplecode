/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Router` holds a list of connections and routes messages between connected users.
*/

import Foundation
import Combine
import SimplePushKit

class Router {
    private let dispatchQueue = DispatchQueue(label: "Router.dispatchQueue", qos: .default)
    private var cancellables = [UUID: Set<AnyCancellable>]()
    private var clients = [UUID: Client]()
    private var calls = [Call]()
    private let logger = Logger(prependString: "Router", subsystem: .general)
    
    init() {}
    
    func register(user: User, session: NetworkSession, type: Channel.ChannelType) {
        dispatchQueue.async {
            let client = self.clients.get(user.uuid, insert: Client(user: user))
            
            if self.cancellables[user.uuid] == nil {
                self.cancellables[user.uuid] = []
                
                client.$notificationChannelState
                .dropFirst()
                .receive(on: self.dispatchQueue)
                .sink { [weak self] state in
                    if state == .disconnected {
                        // The notification channel has disconnected so cancel any pending calls.
                        if let call = self?.call(for: client.user), call.status == .pending {
                            self?.cancel(call: call, with: .unavailable, initiatedBy: client.user)
                        }
                    }
                    
                    // Publish the updated user directory for all users.
                    self?.publishDirectory()
                }
                .store(in: &self.cancellables[user.uuid]!)
                
                client.$controlChannelState
                .dropFirst()
                .receive(on: self.dispatchQueue)
                .sink { [weak self] state in
                    if state == .disconnected {
                        // The control channel has disconnected so cancel any pending or active calls.
                        if let call = self?.call(for: client.user) {
                            self?.cancel(call: call, with: .hangup, initiatedBy: client.user)
                        }
                    }
                }
                .store(in: &self.cancellables[user.uuid]!)
                
                client.messagesPublisher
                .receive(on: self.dispatchQueue)
                .sink { [weak self] message in
                    guard let self = self else {
                        return
                    }
                    
                    self.route(message: message, from: client)
                }
                .store(in: &self.cancellables[user.uuid]!)
                
                client.$user
                .receive(on: self.dispatchQueue)
                .sink { _ in
                    self.publishDirectory()
                }
                .store(in: &self.cancellables[user.uuid]!)
            }
            
            client.user = user
            client.setSession(session, type: type)
            self.publishDirectory()
        }
    }
    
    // MARK: - Routing
    
    func route(message: Codable, from client: Client) {
        switch message {
        case let message as Routable & Codable:
            send(message: message, to: message.routing.receiver)
        case let message as CallAction:
            handleCallAction(message, from: client)
        default:
            break
        }
    }
    
    // MARK: - Call Handling
    
    private func handleCallAction(_ callAction: CallAction, from client: Client) {
        let call: Call! = self.call(for: client.user)
        
        if call == nil {
            switch callAction.action {
            case .connect:
                let receiver = callAction.receiver
                precondition(receiver != nil, "Connected CallActions must always have a receiver.")
                
                // The receiver is already in another Call, let the client know the receiver is unavailable.
                guard self.call(for: receiver!) == nil else {
                    send(message: CallAction(action: .unavailable), to: client.user)
                    return
                }
                
                // Create a new pending Call.
                let newCall = Call(status: .pending, participants: [client.user, callAction.receiver!])
                calls.append(newCall)
                return
            default:
                return
            }
        }
        
        switch callAction.action {
        case .connect where call.status == .pending:
            // Update the call to active.
            call.status = .active
            
            // Let both users know that we have a connected call.
            for user in call.participants {
                send(message: CallAction(action: .connect), to: user)
            }
        case .hangup:
            // Let the other user know that the router is hanging up.
            cancel(call: call, with: .hangup, initiatedBy: client.user)
        case .unavailable:
            // Let the other user know that the receiver is unavailable.
            cancel(call: call, with: .unavailable, initiatedBy: client.user)
        default:
            break
        }
    }
    
    private func cancel(call: Call, with action: CallAction.Action, initiatedBy user: User) {
        if let otherParticipant = otherParticipant(in: call, for: user) {
            send(message: CallAction(action: action), to: otherParticipant)
        }
        
        calls.removeAll { callItem -> Bool in
            callItem == call
        }
    }
    
    private func call(for user: User) -> Call? {
        calls.first { call -> Bool in
            call.participants.contains(user)
        }
    }
    
    private func otherParticipant(in call: Call, for peer: User) -> User? {
        call.participants.first { user -> Bool in
            user != peer
        }
    }
    
    // MARK: - Directory
    
    private var directory: Directory {
        let users = clients.compactMap { _, client -> User? in
            if client.notificationChannelState == .connected {
                return client.user
            } else {
                return nil
            }
        }
        
        return Directory(users: users)
    }
    
    private func publishDirectory() {
        broadcast(message: directory)
    }
    
    // MARK: - Message Forwarding
    
    private func send(message: Codable, to recipient: User) {
        guard let client = clients[recipient.uuid] else {
            return
        }
        
        client.send(message: message)
    }
    
    private func broadcast(message: Codable) {
        for (_, client) in clients {
            client.send(message: message)
        }
    }
}
