/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The primary conduit through which the app communicates with the server's control channel.
*/

import Foundation
import Combine
import SimplePushKit

class ControlChannel: BaseChannel {
    static let shared = ControlChannel()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        super.init(port: Port.control, heartbeatTimeout: .seconds(20), logger: Logger(prependString: "Control Channel", subsystem: .networking))
        
        SettingsManager.shared.settingsPublisher
        .sink { settings in
            self.setHost(settings.host)
        }
        .store(in: &cancellables)
    }
}
