/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model for the `SettingsView`.
*/

import Foundation
import Combine
import SimplePushKit

class SettingsViewModel: ObservableObject {
    @Published var settings: Settings
    @Published var isAppPushManagerActive = false
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(prependString: "SettingsViewModel", subsystem: .general)
    
    init() {
        settings = SettingsManager.shared.settings
        
        // Observe settings published by the SettingsManager to update the SettingsView.
        SettingsManager.shared.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.settings = settings
            }
            .store(in: &cancellables)
        
        // Observe "active" state of NEAppPushManager to display the active state in the SettingsView.
        PushConfigurationManager.shared.pushManagerIsActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAppPushManagerActive in
                self?.isAppPushManagerActive = isAppPushManagerActive
            }
            .store(in: &cancellables)
    }
    
    func commit() {
        do {
            try SettingsManager.shared.set(settings: settings)
        } catch {
            logger.log("Saving to settings failed with error: \(error)")
        }
    }
}
