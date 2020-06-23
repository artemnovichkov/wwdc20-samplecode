/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model for the `UserView`.
*/

import Foundation
import Combine
import SimplePushKit

class UserViewModel: ObservableObject {
    enum PresentedView: Identifiable {
        case messaging(User, TextMessage?)
        
        var id: Int {
            var hasher = Hasher()
            switch self {
            case .messaging(let user, _):
                hasher.combine("messaging")
                hasher.combine(user.id)
            }
            return hasher.finalize()
        }
    }
    
    @Published var user: User
    @Published var userAvailability: UserManager.UserAvailability = .available
    @Published var callState = CallManager.State.disconnected
    @Published var disableCallActions = false
    @Published var helpText = "Start call"
    @Published var presentedView: PresentedView?
    private var cancellables = Set<AnyCancellable>()
    
    init(user: User) {
        self.user = user
        
        // Observe call state changes and update UI accordingly.
        callStatePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] callState in
                self?.callState = callState
            })
            .store(in: &cancellables)
        
        // Observe call and control channel state changes to ensure disabling of the action buttons if the user is in a call with another user or
        // the control channel becomes disconnected from the server.
        CallManager.shared.$state
            .combineLatest(ControlChannel.shared.statePublisher, $userAvailability)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callManagerState, controlChannelState, userAvailability in
                guard let self = self else {
                    return
                }
                
                // Disable call actions if the control channel state becomes disconnected.
                switch controlChannelState {
                case .disconnecting, .disconnected, .connecting:
                    self.disableCallActions = true
                    return
                case .connected:
                    break
                }
                
                // Disable call actions if the user is unavailable.
                guard userAvailability == .available else {
                    self.disableCallActions = true
                    return
                }
                
                // Disable call button when in a call with a user that is different from the user currently being viewed.
                switch callManagerState {
                case .connected(let user):
                    self.updateActionsButtonsForConnectedUser(connectedUser: user)
                case .connecting(let user):
                    self.updateActionsButtonsForConnectedUser(connectedUser: user)
                case .disconnected, .disconnecting:
                    self.disableCallActions = false
                }
            }
            .store(in: &cancellables)
        
        // Observe internal call state, control channel state, and this device's role in the currently active call
        // and set the appropriate help text.
        helpTextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] helpText in
                self?.helpText = helpText
            }
            .store(in: &cancellables)
        
        // Observe user directory changes to update the UI with a user's most recent device name.
        UserManager.shared.userAvailabilityPublisher(for: self.user)
            .sink { [weak self] userAvailability, user in
                self?.user = user
                self?.userAvailability = userAvailability
            }
            .store(in: &cancellables)
        
        // Inform the messaging manager when presenting a user's messaging view.
        $presentedView
            .sink { view in
                if let view = view {
                    switch view {
                    case .messaging(let user, _):
                        MessagingManager.shared.presentedMessageViewUser = user
                        return
                    }
                }
                
                MessagingManager.shared.presentedMessageViewUser = nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Publishers
    
    private lazy var helpTextPublisher = {
        $callState
            .combineLatest(ControlChannel.shared.statePublisher, CallManager.shared.callRolePublisher.replaceNil(with: .sender), $userAvailability)
            .map { callState, controlChannelState, callRole, userAvailability -> String in
                guard controlChannelState == .connected else {
                    return "Connecting to Server"
                }
                
                guard userAvailability == .available else {
                    return "User unavailable"
                }
                
                switch callState {
                case .disconnected:
                    return "Start call"
                case .connecting(let user):
                    switch callRole {
                    case .receiver:
                        return "Receiving call from \(user.deviceName)"
                    case .sender:
                        return "Calling \(user.deviceName)"
                    }
                case .connected(let user):
                    return "Connected with \(user.deviceName)"
                case .disconnecting(let reason) where reason == .unavailable:
                    return "User unavailable"
                case .disconnecting:
                    return "Hanging up"
                }
            }
            .removeDuplicates()
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main) // Debounce changes that occur rapidly.
            .eraseToAnyPublisher()
    }()
    
    // Observes the state of the call manager and returns a new publisher that will either fire immediately or produce a delayed state change. The
    // purpose of the delay is to allow the UI to temporarily display the call termination reason before resetting the UI to a ready state.
    private lazy var callStatePublisher: AnyPublisher<CallManager.State, Never> = {
        CallManager.shared.$state
            .map { [weak self] state -> CallManager.State in
                var connectedUser: User?
                
                switch state {
                case .connected(let user):
                    connectedUser = user
                case .connecting(let user):
                    connectedUser = user
                case .disconnected, .disconnecting:
                    break
                }
                
                if let connectedUser = connectedUser, connectedUser.uuid != self?.user.uuid {
                    return .disconnected
                }
                
                return state
            }
            .scan((nil, .disconnected), { cache, state -> (CallManager.State?, CallManager.State) in
                return (cache.1, state)
            })
            .combineLatest(CallManager.shared.callRolePublisher.dropNil())
            .map { callManagerState, callRole -> AnyPublisher<CallManager.State, Never> in
                let (tempPrevious, next) = callManagerState
                guard let previous = tempPrevious else {
                    return Just(next).eraseToAnyPublisher()
                }
                
                switch previous {
                case .disconnecting(let reason) where next == .disconnected:
                    guard reason != .hungUp && callRole == .sender else {
                        break
                    }
                    
                    // Delay transitioning the UI to the disconnected state so the user can see why the call disconnected.
                    let delayedDisconnectPublisher = Just(next)
                        .delay(for: .seconds(3), scheduler: DispatchQueue.main)
                        .eraseToAnyPublisher()
                    
                    return delayedDisconnectPublisher.eraseToAnyPublisher()
                default:
                    break
                }
                
                return Just(next).eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }()
    
    func updateActionsButtonsForConnectedUser(connectedUser: User) {
        if connectedUser.id == user.id {
            self.disableCallActions = false
        } else {
            self.disableCallActions = true
        }
    }
    
    func phoneButtonDidPress() {
        switch CallManager.shared.state {
        case .connecting, .connected:
            CallManager.shared.endCall()
        case .disconnected:
            CallManager.shared.sendCall(to: user)
        default:
            break
        }
    }
}

extension UserViewModel: Presenter {
    func dismiss() {
        presentedView = nil
    }
}
