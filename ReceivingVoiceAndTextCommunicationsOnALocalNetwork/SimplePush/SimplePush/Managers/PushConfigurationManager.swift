/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A central object for coordinating changes to the NEAppPushManager configuration.
*/

import Foundation
import Combine
import NetworkExtension
import SimplePushKit

class PushConfigurationManager: NSObject {
    static let shared = PushConfigurationManager()
    
    // A publisher that returns the active state of the current push manager.
    private(set) lazy var pushManagerIsActivePublisher = {
        pushManagerIsActiveSubject
        .debounce(for: .milliseconds(500), scheduler: dispatchQueue)
        .eraseToAnyPublisher()
    }()
    
    private let dispatchQueue = DispatchQueue(label: "PushConfigurationManager.dispatchQueue")
    private let logger = Logger(prependString: "PushConfigurationManager", subsystem: .general)
    private var pushManager: NEAppPushManager?
    private let pushManagerDescription = "SimplePushDefaultConfiguration"
    private let pushProviderBundleIdentifier = "com.example.apple-samplecode.SimplePush.SimplePushProvider"
    private let pushManagerIsActiveSubject = CurrentValueSubject<Bool, Never>(false)
    private var pushManagerIsActiveCancellable: AnyCancellable?
    private var initialLoadCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
        // Create, update, or delete the push manager when SettingsManager.hostSSIDPublisher produces a new value.
        SettingsManager.shared.hostSSIDPublisher
            .dropFirst()
            .receive(on: dispatchQueue)
            .compactMap { settings -> AnyPublisher<Result<NEAppPushManager?, Swift.Error>, Never>? in
                var publisher: AnyPublisher<NEAppPushManager?, Swift.Error>?
                
                if !settings.ssid.isEmpty && !settings.host.isEmpty {
                    // Create a new push manager or update the existing instance with the new values from settings.
                    publisher = self.save(pushManager: self.pushManager ?? NEAppPushManager(), with: settings)
                        .flatMap { pushManager in
                            // Reload the push manager.
                            pushManager.load()
                        }
                        .map { $0 }
                        .eraseToAnyPublisher()
                } else if let pushManager = self.pushManager {
                    // Remove the push manager and map its value to nil to indicate removal of the push manager to the downstream subscribers.
                    publisher = pushManager.remove()
                        .map { _ in nil }
                        .eraseToAnyPublisher()
                }
                
                return publisher?.unfailable()
            }
            .switchToLatest()
            .receive(on: dispatchQueue)
            .sink { result in
                switch result {
                case .success(let pushManager):
                    if let pushManager = pushManager {
                        self.prepare(pushManager: pushManager)
                    } else {
                        self.cleanup()
                    }
                case .failure(let error):
                    self.logger.log("\(error)")
                }
            }.store(in: &cancellables)
    }
    
    func initialize() {
        initialLoadCancellable = NEAppPushManager.loadAll()
            .compactMap { pushManagers -> NEAppPushManager? in
                pushManagers.first
            }
            .receive(on: dispatchQueue)
            .sink(receiveCompletion: { _ in
                self.initialLoadCancellable = nil
            }, receiveValue: { pushManager in
                self.prepare(pushManager: pushManager)
            })
    }
    
    private func save(pushManager: NEAppPushManager, with settings: Settings) -> AnyPublisher<NEAppPushManager, Swift.Error> {
        pushManager.matchSSIDs = [settings.ssid]
        pushManager.localizedDescription = self.pushManagerDescription
        pushManager.providerBundleIdentifier = self.pushProviderBundleIdentifier
        pushManager.delegate = self
        pushManager.isEnabled = true
        
        // The provider configuration passes global variables; don't put user specific info in here (which could expose sensitive user info
        // when running on a shared iPad).
        pushManager.providerConfiguration = [
            "host": settings.host
        ]
        
        return pushManager.save()
    }
    
    private func prepare(pushManager: NEAppPushManager) {
        self.pushManager = pushManager
        pushManager.delegate = self
        
        // Observe changes to the manager's `isActive` property and send the value out on the `pushManagerIsActiveSubject`.
        pushManagerIsActiveCancellable = NSObject.KeyValueObservingPublisher(object: pushManager, keyPath: \.isActive, options: [.initial, .new])
        .subscribe(pushManagerIsActiveSubject)
    }
    
    private func cleanup() {
        pushManager = nil
        pushManagerIsActiveCancellable = nil
        pushManagerIsActiveSubject.send(false)
    }
}

extension PushConfigurationManager: NEAppPushDelegate {
    func appPushManager(_ manager: NEAppPushManager, didReceiveIncomingCallWithUserInfo userInfo: [AnyHashable: Any] = [:]) {
        logger.log("NEAppPushDelegate received an incoming call")
        
        guard let senderName = userInfo["senderName"] as? String,
            let senderUUIDString = userInfo["senderUUIDString"] as? String,
            let senderUUID = UUID(uuidString: senderUUIDString) else {
                logger.log("userInfo dictionary is missing a required field")
                return
        }
        
        let sender = User(uuid: senderUUID, deviceName: senderName)
        let routing = Routing(sender: sender, receiver: UserManager.shared.currentUser)
        let invite = Invite(routing: routing)
        
        // Trigger `CallManager` workflow that launches `CallKit` to alert the user to the call.
        CallManager.shared.receiveCall(from: invite)
    }
}

extension NEAppPushManager {
    static func loadAll() -> AnyPublisher<[NEAppPushManager], Error> {
        Future { promise in
            NEAppPushManager.loadAllFromPreferences { managers, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                promise(.success(managers ?? []))
            }
        }.eraseToAnyPublisher()
    }
    
    func load() -> AnyPublisher<NEAppPushManager, Error> {
        Future { promise in
            self.loadFromPreferences { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                promise(.success(self))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func save() -> AnyPublisher<NEAppPushManager, Error> {
        Future { promise in
            self.saveToPreferences { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                promise(.success(self))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func remove() -> AnyPublisher<NEAppPushManager, Error> {
        Future { promise in
            self.removeFromPreferences(completionHandler: { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                promise(.success(self))
            })
        }
        .eraseToAnyPublisher()
    }
}
