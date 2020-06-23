/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`HeartbeatMonitor` is responsible for receiving heartbeats over a `RequestResponseSession`.
*/

import Foundation
import Combine

public class HeartbeatMonitor {
    public enum Error: Swift.Error {
        case missingSession
    }
    
    public var session: RequestResponseSession?
    private let interval: DispatchTimeInterval
    private let dispatchQueue = DispatchQueue(label: "HeartbeatMonitor.dispatchQueue")
    private var isRunning = false
    private var lastCheckinTime: DispatchTime = .now()
    private lazy var timerPublisher = DispatchSource.TimerPublisher(deadline: .now(), repeating: interval, queue: dispatchQueue).share().makeConnectable()
    private var cancellables = Set<AnyCancellable>()
    private let logger: Logger
    
    public init(interval: DispatchTimeInterval, logger: Logger) {
        self.interval = interval
        self.logger = logger
    }
    
    public func start() throws {
        guard let session = session else {
            throw Error.missingSession
        }
        
        dispatchQueue.async { [weak self] in
            guard let self = self,
                self.isRunning == false else {
                    return
            }
            
            self.logger.log("Starting heartbeat monitor")
            
            // Set the lastCheckinTime to now to ensure a clean slate.
            self.lastCheckinTime = .now()
            
            // Observe Heartbeat messages from the session's messagePublisher and update the lastCheckinTime.
            session.messagePublisher
            .compactMap { [weak self] message -> DispatchTime? in
                guard let heartbeat = message as? Heartbeat else {
                    return nil
                }
                
                self?.logger.log("Received - \(heartbeat.count)")
                
                return .now()
            }
            .receive(on: self.dispatchQueue)
            .sink { [weak self] time in
                self?.lastCheckinTime = time
            }
            .store(in: &self.cancellables)
            
            // Observe the timerPublisher, compare the current time to the lastCheckinTime and disconnect the session if the difference between now
            // and lastCheckinTime exceeds the interval.
            self.timerPublisher
            .autoconnect()
            .sink { [weak self] now in
                guard let self = self else {
                    return
                }
                
                let expirationTime = self.lastCheckinTime.advanced(by: self.interval)
                
                if now >= expirationTime {
                    self.logger.log("Heartbeat didn't check in within the interval of \(self.interval), calling network session disconnect.")
                    session.disconnect()
                }
            }
            .store(in: &self.cancellables)
            
            self.isRunning = true
        }
    }
    
    public func stop() {
        dispatchQueue.async { [weak self] in
            guard let self = self, self.isRunning == true else {
                return
            }
            
            self.logger.log("Canceling heartbeat monitor")
            self.isRunning = false
            self.cancellables = []
        }
    }
}
