/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A reusable communication conduit used for the notification and control channel connections to the server.
*/

import Foundation
import Combine
import Network
import SimplePushKit

class BaseChannel {
    private enum ConnectAction {
        case connect(String)
        case disconnect
    }
    
    var state: NetworkSession.State {
        stateSubject.value
    }
    
    private(set) lazy var messagePublisher: AnyPublisher<Codable, Never> = internalMessageSubject.dropNil()
    private(set) lazy var statePublisher: AnyPublisher<NetworkSession.State, Never> = stateSubject.eraseToAnyPublisher()
    private let networkSession = RequestResponseSession()
    private let heartbeatMonitor: HeartbeatMonitor
    private let shouldConnectToServerSubject = CurrentValueSubject<Bool, Never>(false)
    private let hostSubject = CurrentValueSubject<String, Never>("")
    private let stateSubject = CurrentValueSubject<NetworkSession.State, Never>(.disconnected)
    private let registrationSubject = CurrentValueSubject<User?, Never>(nil)
    private let internalMessageSubject = CurrentValueSubject<Codable?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    private let logger: Logger
    
    init(port: UInt16, heartbeatTimeout: DispatchTimeInterval, logger: Logger) {
        self.logger = logger
        networkSession.logger = logger
        heartbeatMonitor = HeartbeatMonitor(interval: heartbeatTimeout, logger: Logger(prependString: "Heartbeat Monitor", subsystem: .heartbeat))
        
        // Observe the network session's state changes and react.
        networkSession.statePublisher
            .combineLatest(registrationSubject)
            .sink { [weak self] state, registration in
                guard let self = self else {
                    return
                }
                
                switch state {
                case .connected:
                    self.heartbeatMonitor.session = self.networkSession
                    
                    do {
                        try self.heartbeatMonitor.start()
                    } catch {
                        self.logger.log("Unable to start hearbeat monitor")
                    }
                    
                    if let registration = registration {
                        self.request(message: registration)
                    }
                case .disconnected:
                    self.heartbeatMonitor.stop()
                default:
                    break
                }
                
                self.stateSubject.send(state)
            }
            .store(in: &cancellables)
        
        // Observe messages from the network session and send them out on messagesSubject.
        networkSession.messagePublisher
            .compactMap { $0 }
            .subscribe(internalMessageSubject)
            .store(in: &cancellables)
        
        // Observe changes to the `connectActionPublisher` and connect or disconnect the session accordingly.
        connectActionPublisher
            .sink { [weak self] connectAction in
                guard let self = self else {
                    return
                }
                
                switch connectAction {
                case .connect(let host):
                    self.logger.log("Connecting to - \(host)")
                    
                    let tls = ConnectionOptions.TLS.Client(publicKeyHash: "XTQSZGrHFDV6KdlHsGVhixmbI/Cm2EMsz2FqE2iZoqU=").options
                    let parameters = NWParameters(tls: tls, tcp: ConnectionOptions.TCP.options)
                    let protocolFramer = NWProtocolFramer.Options(definition: LengthPrefixedFramer.definition)
                    parameters.defaultProtocolStack.applicationProtocols.insert(protocolFramer, at: 0)
                    let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: parameters)
                    
                    self.networkSession.connect(connection: connection)
                case .disconnect:
                    self.logger.log("Calling network session disconnect")
                    self.networkSession.disconnect()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Publishers
    
    // A publisher that signals whether the subscriber should connect to the server or disconnect an existing connection. This publisher takes
    // multiple variables into account, such as the network session's current state, whether this class's connect/disconnect method resulted
    // from an external call, and whether the host changed.
    private lazy var connectActionPublisher: AnyPublisher<ConnectAction, Never> = {
        networkSession.statePublisher
            .combineLatest(shouldConnectToServerSubject, hostSubject.removeDuplicates())
            .scan(nil, { last, next -> (host: String, connect: Bool?)? in
                let (networkSessionState, shouldConnectToServer, host) = next
                var connect: Bool?
                
                if shouldConnectToServer && !host.isEmpty {
                    switch networkSessionState {
                    case .connecting, .connected:
                        guard last?.host != host else {
                            break
                        }
                        // Disconnect if the host changed and the network session is in the connecting or connected state. When network session's
                        // state transitions to .disconnected the next case will cause the channel to try to reconnect.
                        connect = false
                    case .disconnected:
                        // Connect if the server is currently disconnected (retry).
                        connect = true
                    default:
                        break
                    }
                } else {
                    switch networkSessionState {
                    case .connected, .connecting:
                        // Disconnect if the user wants to be disconnected and the session's state is connected or connecting.
                        connect = false
                    default:
                        break
                    }
                }
                
                return (host: host, connect: connect)
            })
            .compactMap { value -> ConnectAction? in
                guard let value = value, let shouldConnect = value.connect else {
                    // It's an indication from the upstream publisher to not proceed if `value` or `value.connect` are nil.
                    return nil
                }
                
                if shouldConnect {
                    return .connect(value.host)
                }
                
                return .disconnect
            }
            .eraseToAnyPublisher()
    }()
    
    // A publisher that upon subscription drops all states from the control channel until receiving a `connected` state, waits for a
    // `disconnecting` state, then finishes.
    public func isDisconnectingPublisher() -> AnyPublisher<NetworkSession.State, Never> {
        statePublisher
            .drop { state -> Bool in
                state != .connected
            }
            .first(where: { state -> Bool in
                state == .disconnecting
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Connection
    
    func connect() {
        shouldConnectToServerSubject.send(true)
    }
    
    func disconnect() {
        shouldConnectToServerSubject.send(false)
    }
    
    func setHost(_ host: String) {
        hostSubject.send(host)
    }
    
    // MARK: - Registration
    
    func register(_ user: User) {
        registrationSubject.send(user)
    }
    
    // MARK: - Requests
    
    public func request<Message: Codable>(message: Message, completion: ((Result<Bool, Swift.Error>) -> Void)? = nil) {
        networkSession.request(message: message, completion: completion)
    }
    
    public func requestPublisher<Message: Codable>(message: Message) -> (requestIdentifier: UInt32, publisher: AnyPublisher<Bool, Swift.Error>) {
        networkSession.requestPublisher(message: message)
    }
}
