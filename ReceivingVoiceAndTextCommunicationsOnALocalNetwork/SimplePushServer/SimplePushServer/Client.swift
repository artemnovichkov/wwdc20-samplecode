/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Client` represents a connected user and manages the user's notification and control channel events.
*/

import Foundation
import Combine
import SimplePushKit

class Client {
    enum State {
        case disconnected
        case connected
    }
    
    struct Connection {
        var uuid = UUID()
        var session: NetworkSession
        var cancellables: Set<AnyCancellable>
        var type: Channel.ChannelType
        var hearbeatCoordinator: HeartbeatCoordinator?
    }
    
    enum Error: Swift.Error {
        case sessionAlreadyExistsForType
    }
    
    @Published var user: User
    @Published private(set) var notificationChannelState: State = .disconnected
    @Published private(set) var controlChannelState: State = .disconnected
    private(set) lazy var messagesPublisher = messagesSubject.eraseToAnyPublisher()
    private let dispatchQueue = DispatchQueue(label: "Client.dispatchQueue", qos: .default)
    private var messagesSubject = PassthroughSubject<Codable, Never>()
    private var notificationIsResponsive = CurrentValueSubject<Bool, Never>(false)
    private var notificationNetworkSessionState = CurrentValueSubject<NetworkSession.State, Never>(.disconnected)
    private var controlNetworkSessionState = CurrentValueSubject<NetworkSession.State, Never>(.disconnected)
    private var cancellables = Set<AnyCancellable>()
    private var networkSessions = [Channel.ChannelType: Connection]()
    private let heartbeatInterval: DispatchTimeInterval = .seconds(10)
    private let logger: Logger
    
    init(user: User) {
        self.user = user
        
        logger = Logger(prependString: "\(user.deviceName) - Client", subsystem: .general)
        
        notificationNetworkSessionState
        .combineLatest(notificationIsResponsive)
        .map { networkSessionState, notificationSessionIsResponsive -> State in
            if networkSessionState == .connected && notificationSessionIsResponsive {
                return State.connected
            } else {
                return State.disconnected
            }
        }
        .removeDuplicates()
        .sink { [weak self] state in
            self?.notificationChannelState = state
        }
        .store(in: &cancellables)
        
        controlNetworkSessionState
        .map { networkSessionState -> State in
            if networkSessionState == .connected {
                return State.connected
            } else {
                return State.disconnected
            }
        }
        .removeDuplicates()
        .sink { [weak self] state in
            self?.controlChannelState = state
        }
        .store(in: &cancellables)
    }
    
    func setSession(_ session: NetworkSession, type: Channel.ChannelType) {
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            let connectionId = UUID()
            var cancellables = Set<AnyCancellable>()
            
            // Update the NetworkSession logger to more easily identify the channel.
            session.logger = Logger(prependString: "\(self.user.deviceName) - \(type.rawValue.capitalized) Channel - NetworkSession", subsystem: .networking)
            
            var heartbeatCoordinator: HeartbeatCoordinator?
            
            if let session = session as? RequestResponseSession {
                let heartbeatLogger = Logger(prependString: "\(self.user.deviceName) - \(type.rawValue.capitalized) Channel - Heartbeat", subsystem: .heartbeat)
                heartbeatCoordinator = HeartbeatCoordinator(interval: self.heartbeatInterval, logger: heartbeatLogger)
                heartbeatCoordinator!.session = session
                
                if type == .notification {
                    // Store the responsiveness of the network session determined by the heartbeat coordinator.
                    heartbeatCoordinator?.$isSessionResponsive
                    .subscribe(self.notificationIsResponsive)
                    .store(in: &cancellables)
                }
            }
            
            // Observe the network session's state.
            session.statePublisher
            .receive(on: self.dispatchQueue)
            .sink { [weak self] state in
                guard let self = self else {
                    return
                }
                
                switch type {
                case .control:
                    self.controlNetworkSessionState.send(state)
                case .notification:
                    self.notificationNetworkSessionState.send(state)
                }
                
                switch state {
                case .connected:
                    self.logger.log("\(type.rawValue.capitalized) Channel did connect")

                    do {
                        try heartbeatCoordinator?.start()
                    } catch {
                        self.logger.log("Unable to start heartbeat coordinator for \(type) channel")
                    }
                case .disconnected:
                    self.logger.log("\(type.rawValue.capitalized) Channel did end")
                    heartbeatCoordinator?.stop()
                    self.cleanupSession(connectionId: connectionId)
                default:
                    break
                }
            }.store(in: &cancellables)
            
            if let session = session as? RequestResponseSession {
                session.messagePublisher
                .receive(on: self.dispatchQueue)
                .sink { [weak self] message in
                    switch message {
                    case is Heartbeat:
                        break
                    case let user as User:
                        self?.user = user
                    default:
                        self?.messagesSubject.send(message)
                    }
                }
                .store(in: &cancellables)
            }
            
            let connection = Connection(uuid: connectionId, session: session, cancellables: cancellables, type: type, hearbeatCoordinator: heartbeatCoordinator)
            self.networkSessions[type] = connection
        }
    }
    
    private func cleanupSession(connectionId: UUID) {
        for (key, connection) in networkSessions where connection.uuid == connectionId {
            logger.log("Removing connection \(connectionId) from network sessions.")
            networkSessions[key] = nil
        }
    }
    
    func send(message: Codable) {
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            // Determine the message type and route the message using the appropriate Channel (Control or Notification).
            switch message {
            case let message as Directory:
                guard let connection = self.networkSessions[.control] else { return }
                self.request(message: message, connection: connection)
            case let message as Invite:
                guard let connection = self.networkSessions[.notification] else { return }
                self.request(message: message, connection: connection)
            case let message as TextMessage:
                guard let connection = self.networkSessions[.notification] else { return }
                self.request(message: message, connection: connection)
            case let message as CallAction:
                guard let connection = self.networkSessions[.control] else { return }
                self.request(message: message, connection: connection)
            default:
                break
            }
        }
    }
    
    private func request<Message: Codable>(message: Message, connection: Connection) {
        guard let session = connection.session as? RequestResponseSession else {
            logger.log("Attempting to send a request to a non-RequestResponseSession")
            return
        }
        
        session.request(message: message) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.logger.log("Request Failed: \(error)")
            default:
                break
            }
        }
    }
}
