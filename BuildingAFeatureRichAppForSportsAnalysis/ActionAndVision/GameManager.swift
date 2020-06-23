/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class manages the game state.
*/

import GameKit

class GameManager {
    
    class State: GKState {
        private(set) var validNextStates: [State.Type]
        
        init(_ validNextStates: [State.Type]) {
            self.validNextStates = validNextStates
            super.init()
        }
        
        func addValidNextState(_ state: State.Type) {
            validNextStates.append(state)
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return validNextStates.contains(where: { stateClass == $0 })
        }
        
        override func didEnter(from previousState: GKState?) {
            let note = GameStateChangeNotification(newState: self, previousState: previousState as? State)
            note.post()
        }
    }
    
    class InactiveState: State {
    }
    
    class SetupCameraState: State {
    }
    
    class DetectingBoardState: State {
    }
    
    class DetectedBoardState: State {
    }

    class DetectingPlayerState: State {
    }
    
    class DetectedPlayerState: State {
    }

    class TrackThrowsState: State {
    }
    
    class ThrowCompletedState: State {
    }

    class ShowSummaryState: State {
    }

    fileprivate var activeObservers = [UIViewController: NSObjectProtocol]()
    
    let stateMachine: GKStateMachine
    var boardRegion = CGRect.null
    var holeRegion = CGRect.null
    var recordedVideoSource: AVAsset?
    var playerStats = PlayerStats()
    var lastThrowMetrics = ThrowMetrics()
    var pointToMeterMultiplier = Double.nan
    var previewImage = UIImage()
    
    static var shared = GameManager()
    
    private init() {
        // Possible states with valid next states.
        let states = [
            InactiveState([SetupCameraState.self]),
            SetupCameraState([DetectingBoardState.self]),
            DetectingBoardState([DetectedBoardState.self]),
            DetectedBoardState([DetectingPlayerState.self]),
            DetectingPlayerState([DetectedPlayerState.self]),
            DetectedPlayerState([TrackThrowsState.self]),
            TrackThrowsState([ThrowCompletedState.self, ShowSummaryState.self]),
            ThrowCompletedState([ShowSummaryState.self, TrackThrowsState.self]),
            ShowSummaryState([DetectingPlayerState.self])
        ]
        // Any state besides Inactive can be returned to Inactive.
        for state in states where !(state is InactiveState) {
            state.addValidNextState(InactiveState.self)
        }
        // Create state machine.
        stateMachine = GKStateMachine(states: states)
    }
    
    func reset() {
        // Reset all stored values
        boardRegion = .null
        recordedVideoSource = nil
        playerStats = PlayerStats()
        pointToMeterMultiplier = .nan
        // Remove all observers and enter inactive state.
        let notificationCenter = NotificationCenter.default
        for observer in activeObservers {
            notificationCenter.removeObserver(observer)
        }
        activeObservers.removeAll()
        stateMachine.enter(InactiveState.self)
    }
}

protocol GameStateChangeObserver: AnyObject {
    func gameManagerDidEnter(state: GameManager.State, from previousState: GameManager.State?)
}

extension GameStateChangeObserver where Self: UIViewController {
    func startObservingStateChanges() {
        let token = NotificationCenter.default.addObserver(forName: GameStateChangeNotification.name,
                                                           object: GameStateChangeNotification.object,
                                                           queue: nil) { [weak self] (notification) in
            guard let note = GameStateChangeNotification(notification: notification) else {
                return
            }
            self?.gameManagerDidEnter(state: note.newState, from: note.previousState)
        }
        let gameManager = GameManager.shared
        gameManager.activeObservers[self] = token
    }
    
    func stopObservingStateChanges() {
        let gameManager = GameManager.shared
        guard let token = gameManager.activeObservers[self] else {
            return
        }
        NotificationCenter.default.removeObserver(token)
        gameManager.activeObservers.removeValue(forKey: self)
    }
}

struct GameStateChangeNotification {
    static let name = NSNotification.Name("GameStateChangeNotification")
    static let object = GameManager.shared
    
    let newStateKey = "newState"
    let previousStateKey = "previousState"

    let newState: GameManager.State
    let previousState: GameManager.State?
    
    init(newState: GameManager.State, previousState: GameManager.State?) {
        self.newState = newState
        self.previousState = previousState
    }
    
    init?(notification: Notification) {
        guard notification.name == Self.name, let newState = notification.userInfo?[newStateKey] as? GameManager.State else {
            return nil
        }
        self.newState = newState
        self.previousState = notification.userInfo?[previousStateKey] as? GameManager.State
    }
    
    func post() {
        var userInfo = [newStateKey: newState]
        if let previousState = previousState {
            userInfo[previousStateKey] = previousState
        }
        NotificationCenter.default.post(name: Self.name, object: Self.object, userInfo: userInfo)
    }
}

typealias GameStateChangeObserverViewController = UIViewController & GameStateChangeObserver
