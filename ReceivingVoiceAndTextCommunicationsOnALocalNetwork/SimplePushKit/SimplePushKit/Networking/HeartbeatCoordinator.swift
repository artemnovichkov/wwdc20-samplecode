/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`HeartbeatCoordinator` is responsible for sending heartbeats over a `RequestResponseSession`.
*/

import Foundation
import Combine

public class HeartbeatCoordinator {
    public enum Error: Swift.Error {
        case missingSession
        case networkSessionError(Swift.Error)
        case nilHeartbeatCoordinator
    }
    
    public enum When {
        case now
        case afterInterval
    }
    
    public var session: RequestResponseSession?
    @Published public private(set) var isSessionResponsive = false
    private let dispatchQueue = DispatchQueue(label: "HeartbeatCoordinator.dispatchQueue")
    private let interval: DispatchTimeInterval
    private var isRunning = false
    private var currentHeartbeatCancellable: AnyCancellable?
    private var heartbeatCount: Int64 = 1
    private let logger: Logger
    
    public init(interval: DispatchTimeInterval, logger: Logger) {
        self.interval = interval
        self.logger = logger
    }
    
    public func start(when: When = .now) throws {
        guard session != nil else {
            throw Error.missingSession
        }
        
        dispatchQueue.async { [weak self] in
            guard let self = self,
                self.isRunning == false else {
                    return
            }
            
            self.logger.log("Starting heartbeat coordinator")
            
            switch when {
            case .now:
                self.heartbeat()
            case .afterInterval:
                self.heartbeat(after: self.interval)
            }
        }
    }
    
    public func stop() {
        logger.log("Canceling heartbeat coordinator")
        
        dispatchQueue.async { [weak self] in
            self?.cleanup()
        }
    }
    
    private func cleanup() {
        isRunning = false
        currentHeartbeatCancellable = nil
    }
    
    private func heartbeat(after: DispatchTimeInterval = .never) {
        guard let session = session else {
            return
        }
        
        var publisher = Just(true)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
        
        if after != .never {
            publisher = publisher
            .delay(for: .init(interval), scheduler: dispatchQueue)
            .eraseToAnyPublisher()
        }
        
        self.currentHeartbeatCancellable = publisher
        .flatMap { [weak self] value -> AnyPublisher<Bool, Error> in
            guard let self = self else {
                return Fail(error: .nilHeartbeatCoordinator).eraseToAnyPublisher()
            }
            
            let heartbeatMessage = Heartbeat(count: self.heartbeatCount)
            self.heartbeatCount += 1
            self.logger.log("Sending - \(heartbeatMessage.count)")
            
            let heartbeatRequestPublisher = session.requestPublisher(message: heartbeatMessage).publisher
            .mapError { error -> Error in
                .networkSessionError(error)
            }
            .eraseToAnyPublisher()
            
            return heartbeatRequestPublisher
        }
        .receive(on: dispatchQueue)
        .sink(receiveCompletion: { [weak self] completion in
            guard let self = self else {
                return
            }
            
            switch completion {
            case .finished:
                self.isSessionResponsive = true
                self.logger.log("Finished successfully, rescheduling in \(self.interval)...")
            case .failure:
                self.isSessionResponsive = false
                self.logger.log("Failed")
            }
            
            self.heartbeat(after: self.interval)
        }, receiveValue: { _ in
            // Do nothing with values; this sink only listens for completion.
        })
        
        isRunning = true
    }
}
