/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`NetworkSession` is an abstract base class that manages a NWConnection and handles connection retries.
*/

import Foundation
import Network
import Combine

public class NetworkSession {
    public enum State: String, Equatable {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }
    
    public enum Error: Swift.Error {
        case notConnected
        case connectionFailed(Swift.Error)
        case connectionCancelled
    }
    
    public var state: State {
        stateSubject.value
    }
    
    public var logger: Logger {
        get {
            os_unfair_lock_lock(lock)
            let logger = _logger
            os_unfair_lock_unlock(lock)
            return logger
        }
        set {
            os_unfair_lock_lock(lock)
            _logger = newValue
            os_unfair_lock_unlock(lock)
        }
    }
    
    public private(set) lazy var statePublisher = {
        stateSubject
        .removeDuplicates()
        .eraseToAnyPublisher()
    }()
    
    private(set) var connection: NWConnection?
    private let dispatchQueue = DispatchQueue(label: "NetworkSession.dispatchQueue")
    private let stateSubject = CurrentValueSubject<State, Never>(.disconnected)
    private let retryInterval = DispatchTimeInterval.seconds(5)
    private var retryWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    private let lock = os_unfair_lock_t.allocate(capacity: 1)
    private var _logger = Logger(prependString: "NetworkSession", subsystem: .networking)
    
    public init() {
        stateSubject.sink { [weak self] state in
            self?.logger.log("State - \(state)")
        }.store(in: &cancellables)
    }
    
    public func connect(connection: NWConnection) {
        dispatchQueue.async { [weak self] in
            guard let self = self, self.stateSubject.value == .disconnected else {
                return
            }
            
            self.stateSubject.send(.connecting)
            
            connection.stateUpdateHandler = { [weak self] state in
                guard let self = self else {
                    return
                }
                
                self.logger.log("Connection State - \(state)")
                
                switch state {
                case .waiting(let error):
                    self.logger.log(error.debugDescription)
                    self.retry(after: self.retryInterval, error: error)
                case .ready:
                    self.stateSubject.send(.connected)
                    self.receive()
                case .failed(let error):
                    self.logger.log(error.debugDescription)
                    self.disconnect()
                case .cancelled:
                    self.stateSubject.send(.disconnected)
                default:
                    break
                }
            }
            
            connection.start(queue: self.dispatchQueue)
            
            self.connection = connection
        }
    }
    
    public func disconnect() {
        dispatchQueue.async { [weak self] in
            guard let self = self, [.connecting, .connected].contains(self.stateSubject.value) else {
                return
            }
            
            self.logger.log("Disconnect was called")
            
            self.stateSubject.send(.disconnecting)
            self.cancelRetry()
            self.connection?.cancel()
        }
    }
    
    // MARK: - Retry
    
    private func retry(after delay: DispatchTimeInterval, error: NWError) {
        cancelRetry()
        
        guard let connection = connection else {
            return
        }

        var retry = true
        
        switch error {
        case .posix(let code):
            logger.log("POSIX Error Code - \(code)")
            switch code {
            case .ENETDOWN, .ENETUNREACH, .EHOSTDOWN, .EHOSTUNREACH:
                retry = false
            default:
                break
            }
        case .tls(let code):
            logger.log("TLS Error Code - \(code)")
        case .dns(let code):
            logger.log("DNS Error Code - \(code)")
        default:
            logger.log("Unknown error type encountered in \(#function)")
        }
        
        guard retry else {
            return
        }
        
        retryWorkItem = DispatchWorkItem { [weak self] in
            self?.logger.log("Retrying to connect with remote server...")
            connection.restart()
        }
        
        dispatchQueue.asyncAfter(deadline: .now() + delay, execute: retryWorkItem!)
    }
    
    private func cancelRetry() {
        guard let retryWorkItem = retryWorkItem else {
            return
        }
        
        retryWorkItem.cancel()
        self.retryWorkItem = nil
    }
    
    // MARK: - Send
    
    internal func send(data: Data) {
        connection?.send(content: data, completion: .contentProcessed({ [weak self] error in
            if let error = error {
                self?.logger.log("Error sending - \(error)")
            }
        }))
    }
    
    internal func send(data: Data, context: NWConnection.ContentContext) {
        dispatchQueue.async { [weak self] in
            guard self?.state == .connected else {
                return
            }
            
            self?.connection?.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed({ [weak self] error in
                if let error = error {
                    self?.logger.log("Error sending - \(error)")
                }
            }))
        }
    }
    
    // MARK: - Receive
    
    internal func receive() {}
}
