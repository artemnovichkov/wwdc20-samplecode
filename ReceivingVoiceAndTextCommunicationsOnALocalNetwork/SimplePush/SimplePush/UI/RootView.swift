/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main container view of the app that orchestrates presenting views in response to external events.
*/

import SwiftUI
import SimplePushKit

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel
    var content: () -> DirectoryView
    
    init(viewModel: RootViewModel, content: @escaping () -> DirectoryView) {
        self.viewModel = viewModel
        self.content = content
    }
    
    var body: some View {
        content().sheet(item: $viewModel.presentedView) { presentedView in
            self.view(for: presentedView)
        }
    }
    
    @ViewBuilder func view(for presentedView: RootViewModel.PresentedView) -> some View {
        switch presentedView {
        case .settings:
            let settingsViewModel = SettingsViewModel()
            SettingsView(viewModel: settingsViewModel, presenter: viewModel)
        case .user(let user, let message):
            userView(user: user, message: message)
        }
    }
    
    private func userView(user: User, message: TextMessage?) -> UserView {
        let userViewModel = viewModel.viewModel(for: user)
        if let message = message {
            userViewModel.presentedView = .messaging(user, message)
        }
        return UserView(viewModel: userViewModel, presenter: viewModel)
    }
}
