/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model for the `RootView`.
*/

import Foundation
import SwiftUI
import Combine
import SimplePushKit

class RootViewModel: ObservableObject {
    enum PresentedView: Identifiable {
        case settings
        case user(User, TextMessage?)
        
        var id: Int {
            var hasher = Hasher()
            switch self {
            case .settings:
                hasher.combine("settings")
            case .user(let user, _):
                hasher.combine("user")
                hasher.combine(user.id)
            }
            return hasher.finalize()
        }
    }
    
    @Published var presentedView: PresentedView?
    private var userViewModels = [UUID: UserViewModel]()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Present the user view when answering a call.
        CallManager.shared.$state
        .receive(on: DispatchQueue.main)
        .sink { state in
            switch state {
            case .connected(let user):
                self.presentedView = .user(user, nil)
            default:
                break
            }
        }
        .store(in: &cancellables)
        
        // Present a user's messaging view when receiving a text message.
        MessagingManager.shared.messagePublisher
        .receive(on: DispatchQueue.main)
        .sink { message in
            let user = message.routing.sender
            self.presentedView = PresentedView.user(user, message)
        }
        .store(in: &cancellables)
    }
    
    func viewModel(for user: User) -> UserViewModel {
        userViewModels.get(user.id, insert: UserViewModel(user: user))
    }
}

extension RootViewModel: Presenter {
    func dismiss() {
        presentedView = nil
    }
}
