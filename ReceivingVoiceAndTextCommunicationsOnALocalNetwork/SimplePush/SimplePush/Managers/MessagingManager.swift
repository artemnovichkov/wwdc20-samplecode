/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A central object for managing incoming and outgoing messages.
*/

import Foundation
import Combine
import UserNotifications
import SimplePushKit

class MessagingManager: NSObject {
    static let shared = MessagingManager()
    
    var presentedMessageViewUser: User?
    private(set) lazy var messagePublisher = messageSubject.dropNil()
    private lazy var messageSubject = PassthroughSubject<TextMessage?, Never>()
    private let logger = Logger(prependString: "MessagingManager", subsystem: .general)
    
    func initialize() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted == true && error == nil {
                self.logger.log("Notification permission granted")
            } else {
                self.logger.log("Notification permission denied")
            }
        }
    }
    
    func send(message: String, to receiver: User) {
        let sender = UserManager.shared.currentUser
        let routing = Routing(sender: sender, receiver: receiver)
        let textMessage = TextMessage(routing: routing, message: message)
        
        logger.log("Sending text message to \(receiver.deviceName) through Control Channel")
        
        ControlChannel.shared.request(message: textMessage)
    }
    
    private func textMessage(from notification: UNNotification) -> TextMessage? {
        guard let messageBody = notification.request.content.userInfo["message"] as? String,
            let senderName = notification.request.content.userInfo["senderName"] as? String,
            let senderUUIDString = notification.request.content.userInfo["senderUUID"] as? String,
            let senderUUID = UUID(uuidString: senderUUIDString) else {
                self.logger.log("Notification was missing required user information and cannot be loaded")
                return nil
        }
        
        let sender = User(uuid: senderUUID, deviceName: senderName)
        let routing = Routing(sender: sender, receiver: UserManager.shared.currentUser)
        let message = TextMessage(routing: routing, message: messageBody)
        
        return message
    }
}

extension MessagingManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let message = textMessage(from: notification) else {
            return completionHandler([.badge, .sound, .banner])
        }
        
        // If a message was received, and the user matches the one shown by the current `MessagingView`, load the message
        // in the `MessagingView`. Otherwise, present the standard notification.
        if let presentedMessageViewUser = presentedMessageViewUser, presentedMessageViewUser.uuid == message.routing.sender.uuid {
            completionHandler([])
            messageSubject.send(message)
        } else {
            completionHandler([.badge, .sound, .banner])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let message = textMessage(from: response.notification) else {
            completionHandler()
            return
        }
        
        messageSubject.send(message)
        completionHandler()
    }
}
