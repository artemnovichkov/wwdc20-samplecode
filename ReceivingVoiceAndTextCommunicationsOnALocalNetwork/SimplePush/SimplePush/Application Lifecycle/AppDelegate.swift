/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A delegate that receives messages about app life cycle events.
*/

import UIKit
import Combine
import Network
import UserNotifications
import SimplePushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let logger = Logger(prependString: "AppDelegate", subsystem: .general)
    private var cancellables = Set<AnyCancellable>()
    private let dispatchQueue = DispatchQueue(label: "AppDelegate.dispatchQueue")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PushConfigurationManager.shared.initialize()
        MessagingManager.shared.initialize()
        MessagingManager.shared.requestNotificationPermission()
        
        // Register this device with the control channel.
        let user = User(uuid: UserManager.shared.currentUser.uuid, deviceName: UserManager.shared.currentUser.deviceName)
        ControlChannel.shared.register(user)
        
        // Connect the control channel when the app is in the foreground or responding to a CallKit call in the background.
        // Disconnect the control channel when the app is in the background and not in a CallKit call.
        isExecutingInBackgroundPublisher
            .combineLatest(CallManager.shared.$state)
            .sink { isExecutingInBackground, callManagerState in
                if isExecutingInBackground {
                    switch callManagerState {
                    case .connecting:
                        self.logger.log("App running in background and the CallManager's state is connecting, connecting to control channel")
                        ControlChannel.shared.connect()
                    case .disconnected:
                        self.logger.log("App running in background and the CallManager's state is disconnected, disconnecting from control channel")
                        ControlChannel.shared.disconnect()
                    default:
                        break
                    }
                } else {
                    self.logger.log("App running in foreground, connecting to control channel")
                    ControlChannel.shared.connect()
                }
            }
            .store(in: &cancellables)
        
        return true
    }
    
    // Produces a Boolean to indicate whether the app is currently executing in the foreground or background.
    private lazy var isExecutingInBackgroundPublisher: AnyPublisher<Bool, Never> = {
        Just(true)
        .merge(with:
            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
            .map { notification -> Bool in
                notification.name == UIApplication.didEnterBackgroundNotification
            }
        )
        .debounce(for: .milliseconds(100), scheduler: dispatchQueue)
        .eraseToAnyPublisher()
    }()
    
    // MARK: UISceneSession Life Cycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // MARK: UIApplication Life Cycle
    
    func applicationWillTerminate(_ application: UIApplication) {
        logger.log("Application is terminating, disconnecting control channel")
        ControlChannel.shared.disconnect()
    }
}
