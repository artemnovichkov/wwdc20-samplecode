/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A central object for managing the current user and list of connected users.
*/

import UIKit
import Combine
import SimplePushKit

class UserManager {
    enum UserAvailability {
        case available
        case unavailable
    }
    
    static let shared = UserManager()
    
    private(set) lazy var usersPublisher = usersSubject.dropNil()
    private(set) var currentUser = SettingsManager.shared.settings.user
    private let dispatchQueue = DispatchQueue(label: "UserManager.dispatchQueue")
    private var usersSubject = CurrentValueSubject<[User]?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe updates to the directory list broadcast by the server.
        ControlChannel.shared.messagePublisher
            .receive(on: dispatchQueue)
            .compactMap { message -> [User]? in
                guard let directory = message as? Directory else {
                    return nil
                }
                
                // Returns an array of users sorted alphabetically with the current user's own record removed from the list.
                return directory.users.filter { user in
                    user.uuid != self.currentUser.uuid
                }.sorted { user1, user2 -> Bool in
                    user1.deviceName < user2.deviceName
                }
            }
            .subscribe(usersSubject)
            .store(in: &cancellables)
        
        // Observe UIApplication.didBecomeActiveNotification and update the user's device name in the SettingsManager.
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in
                var settings = SettingsManager.shared.settings
                settings.deviceName = UIDevice.current.name
                try? SettingsManager.shared.set(settings: settings)
            }
            .store(in: &cancellables)
        
        // Observe changes to settings and send a new `User` to the server when the `currentUser` changes their info.
        SettingsManager.shared.settingsPublisher
            .combineLatest(ControlChannel.shared.statePublisher)
            .receive(on: dispatchQueue)
            .filter { settings, state -> Bool in
                self.currentUser != settings.user && state == .connected
            }
            .sink { settings, state in
                ControlChannel.shared.request(message: settings.user)
                self.currentUser = settings.user
            }
            .store(in: &cancellables)
    }
    
    func userAvailabilityPublisher(for comparedUser: User) -> AnyPublisher<(UserAvailability, User), Never> {
        usersPublisher
            .receive(on: DispatchQueue.main)
            .map { users -> (UserAvailability, User) in
                for user in users where user.uuid == comparedUser.uuid {
                    return (.available, user)
                }
                return (.unavailable, comparedUser)
            }
            .eraseToAnyPublisher()
    }
}
