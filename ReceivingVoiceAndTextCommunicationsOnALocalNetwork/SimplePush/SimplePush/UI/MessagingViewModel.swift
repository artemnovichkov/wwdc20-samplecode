/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model for the `MessagingView`.
*/

import Foundation
import Combine
import SimplePushKit

class MessagingViewModel: ObservableObject {
    @Published var message: TextMessage?
    @Published var reply: String = ""
    @Published var textActionsAreDisabled = false
    private let receiver: User
    private var cancellables = Set<AnyCancellable>()
    
    init(receiver: User, message: TextMessage?) {
        self.receiver = receiver
        self.message = message
        
        // Observes when the message publisher has a message which will place the UI in a "reply" mode.
        MessagingManager.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.message = message
            }
            .store(in: &cancellables)
        
        // Observe control channel state changes to ensure disabling of the action button if the device is disconnected.
        ControlChannel.shared.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] controlChannelState in
                switch controlChannelState {
                case .disconnecting, .disconnected, .connecting:
                    self?.textActionsAreDisabled = true
                case .connected:
                    self?.textActionsAreDisabled = false
                }
            }
            .store(in: &cancellables)
    }
    
    func sendMessage() {
        guard !reply.isEmpty else {
            return
        }
        
        MessagingManager.shared.send(message: reply, to: receiver)
    }
}
