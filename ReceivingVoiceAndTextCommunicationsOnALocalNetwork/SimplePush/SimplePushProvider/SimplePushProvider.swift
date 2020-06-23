/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `NEAppPushProvider` that establishes a connection to the server and listens for messages and call invites.
*/

import Foundation
import Combine
import NetworkExtension
import UserNotifications
import SimplePushKit

class SimplePushProvider: NEAppPushProvider {
    private let channel = BaseChannel(port: Port.notification, heartbeatTimeout: .seconds(60), logger: Logger(prependString: "Notification Channel", subsystem: .networking))
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(prependString: "SimplePushProvider", subsystem: .general)
    
    override init() {
        super.init()
        
        logger.log("Initialized")
        
        // Observe notification channel connection state changes for logging purposes.
        channel.statePublisher
            .sink { [weak self] state in
                self?.logger.log("Notification channel state changed to: \(state)")
            }
            .store(in: &cancellables)
        
        // Observe notification channel messages and alert user when receiving a new text message or call invite.
        channel.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else {
                    return
                }
                
                switch message {
                case let message as Invite:
                    self.reportIncomingCall(invite: message)
                case let message as TextMessage:
                    self.showLocalNotification(message: message)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe changes to Settings to send new user registrations on the notification channel when receiving a Settings change.
        SettingsManager.shared.settingsPublisher
            .sink { [weak self] settings in
                guard let self = self else {
                    return
                }
                
                let user = User(uuid: settings.uuid, deviceName: settings.deviceName)
                self.channel.register(user)
                self.channel.setHost(settings.host)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - NEAppPushProvider Life Cycle
    
    override func start(completionHandler: @escaping (Error?) -> Void) {
        logger.log("Started")
        
        guard let host = providerConfiguration?["host"] as? String else {
            logger.log("Provider configuration is missing value for key: `host`")
            completionHandler(nil)
            return
        }
        
        channel.setHost(host)
        channel.connect()
        
        completionHandler(nil)
    }
    
    override func stop(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.log("Stopped with reason \(reason)")
        
        channel.disconnect()
        completionHandler()
    }
    
    // MARK: - Notify User
    
    func showLocalNotification(message: TextMessage) {
        logger.log("Received text message from \(message.routing.sender.deviceName)")
        
        let content = UNMutableNotificationContent()
        content.title = message.routing.sender.deviceName
        content.body = message.message
        content.sound = .default
        content.userInfo = [
            "senderName": message.routing.sender.deviceName,
            "senderUUID": message.routing.sender.uuid.uuidString,
            "message": message.message
        ]
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.log("Error submitting local notification: \(error)")
                return
            }
            
            self?.logger.log("Local notification posted successfully")
        }
    }
    
    func reportIncomingCall(invite: Invite) {
        logger.log("Received incoming call from \(invite.routing.sender.deviceName)")
        
        let callInfo = [
            "senderName": invite.routing.sender.deviceName,
            "senderUUIDString": invite.routing.sender.uuid.uuidString
        ]
        
        self.reportIncomingCall(userInfo: callInfo)
    }
}
