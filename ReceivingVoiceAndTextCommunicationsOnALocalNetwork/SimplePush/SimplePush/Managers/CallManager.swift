/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A central object for managing the state of a call and coordinating interaction with CallKit.
*/

import Foundation
import Combine
import CallKit
import SimplePushKit

class CallManager: NSObject {
    static let shared = CallManager()
    
    enum State: Hashable {
        case disconnected
        case connecting(user: User)
        case connected(user: User)
        case disconnecting(reason: TerminatedReason)
    }
    
    enum InternalCallAction {
        case connect
        case broadcastAudio
        case hangUp(reason: TerminatedReason)
        case disconnect
    }
    
    enum CallRole {
        case sender
        case receiver
    }
    
    enum TerminatedReason {
        case hungUp
        case callFailed
        case unavailable
    }
    
    @Published private(set) var state: State = .disconnected
    
    private(set) lazy var callRolePublisher: AnyPublisher<CallRole?, Never> = {
        callRoleSubject.eraseToAnyPublisher()
    }()
    
    private lazy var provider: CXProvider = {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = false
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        return CXProvider(configuration: configuration)
    }()
    
    private let dispatchQueue = DispatchQueue(label: "CallManager.dispatchQueue", qos: .default)
    private let callController = CXCallController()
    private var currentCallUUID: UUID?
    private var remoteUser: User?
    private let callActionSubject = CurrentValueSubject<InternalCallAction?, Never>(nil)
    private let callRoleSubject = CurrentValueSubject<CallRole?, Never>(nil)
    private let callIsAnsweredSubject = CurrentValueSubject<Bool, Never>(false)
    private let callShouldEndSubject = PassthroughSubject<Bool, Never>()
    private var callHangupCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(prependString: "CallManager", subsystem: .callKit)
    
    override init() {
        super.init()
        
        provider.setDelegate(self, queue: dispatchQueue)
        
        // Observe when state updates.
        nextStatePublisher
            .receive(on: dispatchQueue)
            .sink { state in
                self.state = state
                
                switch state {
                case .connecting:
                    self.logger.log("State changed to connecting")
                case .connected(let user):
                    self.logger.log("State changed to connected to - \(user.deviceName)")
                case .disconnecting(let reason):
                    self.logger.log("State changed to disconnecting with reason - \(reason)")
                    self.remoteUser = nil
                    self.callActionSubject.send(.disconnect)
                case .disconnected:
                    self.logger.log("State changed to disconnected")
                }
            }
            .store(in: &cancellables)
        
        // Observe call statuses sent from the remoteUser when in an active call. Call status messages signal actions to perform,
        // such as connect, or hang up.
        ControlChannel.shared.messagePublisher
            .compactMap { message -> CallAction? in
                message as? CallAction
            }
            .receive(on: dispatchQueue)
            .sink { callAction in
                guard let remoteUser = self.remoteUser else {
                    return
                }
                
                self.logger.log("Received remote CallAction of \(callAction.action) from \(remoteUser.deviceName)")
                
                switch callAction.action {
                case .connect:
                    self.callActionSubject.send(.broadcastAudio)
                case .hangup:
                    self.remoteEndCall(reason: .remoteEnded)
                case .unavailable:
                    self.remoteEndCall(reason: .unanswered)
                }
            }
            .store(in: &cancellables)
        
        // End an active call if the call manager's state is `connecting` or `connected` and the control channel has moved to `disconnecting`
        // immediately from `connected` (see ControlChannel.isDisconnectingPublisher() for more details).
        $state
            .map { state -> AnyPublisher<NetworkSession.State, Never> in
                switch state {
                case .connecting, .connected:
                    return ControlChannel.shared.isDisconnectingPublisher()
                default:
                    return Empty().eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .sink { controlChannelState in
                self.logger.log("Ending the call because control channel state moved to \(controlChannelState) while in a call")
                self.remoteEndCall(reason: .failed)
            }
            .store(in: &cancellables)
        
        // Observe when the user answers the call.
        callIsAnsweredSubject
            .sink { isAnswered in
                guard isAnswered, let remoteUser = self.remoteUser else {
                    return
                }
                
                let callAction = CallAction(action: .connect, receiver: remoteUser)
                ControlChannel.shared.request(message: callAction)
            }
            .store(in: &cancellables)
        
        // Ensures sending of a hang up status to the remoteUser before fulfilling a CallKit action that could potentially terminate the call.
        shouldFullfillHangUpPublisher
            .subscribe(callShouldEndSubject)
            .store(in: &cancellables)
        
        // Inform CallKit when a the remoteUser device name changes.
        updatedRemoteUserPublisher
            .receive(on: dispatchQueue)
            .sink { remoteUser in
                self.remoteUser = remoteUser
                self.updateCallHandle(displayName: remoteUser.deviceName)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Publishers
    
    // Produces a new state based on actions sent to `callActionSubject` and the state of `callIsAnsweredSubject`.
    private lazy var nextStatePublisher: AnyPublisher<CallManager.State, Never> = {
        callActionSubject
            .combineLatest(callIsAnsweredSubject)
            .receive(on: dispatchQueue)
            .compactMap { action, isAnswered -> State? in
                self.logger.log("New call action - \(String(describing: action.debugDescription))")
                
                switch action {
                case .connect:
                    guard case State.disconnected = self.state, let remoteUser = self.remoteUser else { break }
                    return .connecting(user: remoteUser)
                case .broadcastAudio:
                    guard case State.connecting = self.state else { break }
                    
                    if isAnswered, let remoteUser = self.remoteUser {
                        return .connected(user: remoteUser)
                    }
                case .hangUp(let reason):
                    if self.state == .disconnected { break }
                    return .disconnecting(reason: reason)
                case .disconnect:
                    guard case State.disconnecting = self.state else { break }
                    return .disconnected
                default:
                    break
                }
                
                return nil
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()
    
    // A publisher that returns a new User model for the current `remoteUser`.
    private lazy var updatedRemoteUserPublisher: AnyPublisher<User, Never> = {
        UserManager.shared.usersPublisher
            .receive(on: dispatchQueue)
            .compactMap { users -> User? in
                guard let remoteUser = self.remoteUser else {
                    return nil
                }
                
                for user in users where user.uuid == remoteUser.uuid && user != remoteUser {
                    return user
                }
                
                return nil
            }
            .eraseToAnyPublisher()
    }()
    
    // Ensures that a hang up status is sent to the remoteUser before fulfilling a CallKit action that could potentially terminate the CallKit call.
    private lazy var shouldFullfillHangUpPublisher: AnyPublisher<Bool, Never> = {
        $state
            .compactMap { state -> (TerminatedReason, User)? in
                switch state {
                case .disconnecting(let reason):
                    guard let remoteUser = self.remoteUser else {
                        return nil
                    }
                    return (reason, remoteUser)
                default:
                    return nil
                }
            }
            .flatMap { reason, remoteUser -> AnyPublisher<Result<Bool, Error>, Never> in
                var callAction: CallAction.Action
                
                switch reason {
                case .unavailable:
                    callAction = .unavailable
                default:
                    callAction = .hangup
                }
                
                self.logger.log("Sending CallStatus of \(callAction) to \(remoteUser.deviceName)")
                
                let callActionMessage = CallAction(action: callAction, receiver: remoteUser)
                let (_, publisher) = ControlChannel.shared.requestPublisher(message: callActionMessage)
                
                return publisher.unfailable()
            }
            .map { _ in
                // Signal that it's okay to hangup whether sending the call status to the remoteUser succeeded or failed.
                true
            }
            .eraseToAnyPublisher()
    }()
    
    // MARK: - Actions
    
    func sendCall(to remoteUser: User) {
        dispatchQueue.async {
            guard self.state == .disconnected else {
                return
            }
            
            self.callRoleSubject.send(.sender)
            self.remoteUser = remoteUser
            
            let routing = Routing(sender: UserManager.shared.currentUser, receiver: remoteUser)
            let invite = Invite(routing: routing)
            ControlChannel.shared.request(message: invite)
            
            self.callActionSubject.send(.connect)
            self.logger.log("Sending CXStartCallAction transaction to CallKit")
            
            let callUUID = UUID()
            self.currentCallUUID = callUUID
            let startCallAction = CXStartCallAction(call: callUUID, handle: CXHandle(type: .generic, value: remoteUser.deviceName))
            startCallAction.isVideo = false
            let transaction = CXTransaction(action: startCallAction)
            
            self.requestCallKitTransaction(transaction)
        }
    }
    
    func receiveCall(from invite: Invite) {
        dispatchQueue.async {
            guard self.state == .disconnected else {
                return
            }
            
            self.callRoleSubject.send(.receiver)
            self.remoteUser = invite.routing.sender
            self.callActionSubject.send(.connect)
            
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: self.remoteUser!.deviceName)
            update.hasVideo = false
            
            let callUUID = UUID()
            self.currentCallUUID = callUUID
            
            self.provider.reportNewIncomingCall(with: callUUID, update: update) { error in
                if let error = error {
                    self.logger.log("Report incoming call failed: \(error)")
                    self.cleanUpActiveCall(reason: .unavailable)
                    return
                }
            }
        }
    }
    
    func endCall() {
        dispatchQueue.async {
            guard let callUUID = self.currentCallUUID else {
                self.logger.log("Unable to end call because currentCallUUID is nil")
                return
            }
            
            let action = CXEndCallAction(call: callUUID)
            let transaction = CXTransaction(action: action)
            self.requestCallKitTransaction(transaction)
        }
    }
    
    // MARK: - Call Actions
    
    private func cleanUpActiveCall(reason: TerminatedReason) {
        callIsAnsweredSubject.send(false)
        callActionSubject.send(.hangUp(reason: reason))
        currentCallUUID = nil
        callRoleSubject.send(nil)
    }
    
    private func requestCallKitTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                self.logger.log("Error requesting CallKit transaction - \(error)")
            }
        }
    }
    
    private func updateCallHandle(displayName: String) {
        guard let currentCallUUID = currentCallUUID else { return }
        
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: displayName)
        self.provider.reportCall(with: currentCallUUID, updated: update)
    }
    
    private func remoteEndCall(reason: CXCallEndedReason) {
        dispatchQueue.async {
            guard let currentCallUUID = self.currentCallUUID else {
                return
            }
            
            var internalReason: TerminatedReason
            switch reason {
            case .remoteEnded:
                internalReason = .hungUp
            case .unanswered:
                internalReason = .unavailable
            default:
                internalReason = .callFailed
            }
            
            self.logger.log("Reporting remote end call to CallKit")
            self.provider.reportCall(with: currentCallUUID, endedAt: nil, reason: reason)
            self.cleanUpActiveCall(reason: internalReason)
        }
    }
}

extension CallManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        logger.log("Provider did reset")
        callIsAnsweredSubject.send(false)
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        logger.log("Provider perform answer call action")
        callIsAnsweredSubject.send(true)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        logger.log("Provider perform end call action")
        precondition(callRoleSubject.value != nil, "Call role is nil, this shouldn't have happened")
        
        dispatchQueue.async {
            switch self.state {
            case .connecting:
                switch self.callRoleSubject.value! {
                case .sender:
                    self.cleanUpActiveCall(reason: .hungUp)
                case .receiver:
                    self.cleanUpActiveCall(reason: .unavailable)
                }
            case .connected:
                self.cleanUpActiveCall(reason: .hungUp)
            case .disconnected, .disconnecting:
                break
            }
        }

        // Wait until `shouldFulfillHangupSubject` produces a value that indicates it's okay to end the call, otherwise the app process could
        // terminated before the hangup was sent to the `remoteUser`.
        callHangupCancellable = callShouldEndSubject
        .sink(receiveValue: { [weak self] _ in
            guard let self = self else {
                return
            }
            
            self.logger.log("Fulfilling call hang up action")
            self.callHangupCancellable = nil
            action.fulfill()
        })
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        logger.log("Provider perform start call action")
        callIsAnsweredSubject.send(true)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        logger.log("Provider timed out performing action - \(action)")
        callIsAnsweredSubject.send(false)
        callHangupCancellable = nil
        callActionSubject.send(.hangUp(reason: .callFailed))
        action.fulfill()
    }
}
