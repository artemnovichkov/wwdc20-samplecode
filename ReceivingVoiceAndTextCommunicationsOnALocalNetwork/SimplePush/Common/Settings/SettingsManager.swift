/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A central object for persisting the application's settings.
*/

import Foundation
import UIKit
import Combine
import os
import SimplePushKit

class SettingsManager: NSObject {
    enum Error: Swift.Error {
        case uuidMismatch
    }
    
    static let shared = SettingsManager()
    
    var settings: Settings {
        settingsSubject.value
    }
    
    private(set) lazy var settingsPublisher = settingsSubject.eraseToAnyPublisher()
    private static let settingsKey = "settings"
    private static let userDefaults = UserDefaults(suiteName: "group.com.example.apple-samplecode.SimplePush")!
    private let settingsSubject: CurrentValueSubject<Settings, Never>
    private var cancellables = Set<AnyCancellable>()
    private static let logger = Logger(prependString: "SettingsManager", subsystem: .general)
    
    override init() {
        var settings = Self.fetch()
        
        if settings == nil {
            settings = Settings(uuid: UUID(), deviceName: UIDevice.current.name, ssid: "", host: "")
            
            do {
                try Self.set(settings: settings!)
            } catch {
                SettingsManager.logger.log("Error encoding settings - \(error)")
            }
        }
        
        settingsSubject = CurrentValueSubject(settings!)
        
        super.init()
        
        Self.userDefaults.addObserver(self, forKeyPath: Self.settingsKey, options: [.new], context: nil)
    }
    
    // MARK: - Publishers
    
    // A publisher that observes the settingsSubject and ensures it publishes only unique host/ssid values.
    private(set) lazy var hostSSIDPublisher = {
        settingsSubject
            .scan((false, nil), { previousResult, settings -> (Bool, Settings?) in
                guard let previousSettings = previousResult.1 else {
                    // If this is the first call to this publisher, pass the settings through since we don't have previous settings
                    // to compare against.
                    return (true, settings)
                }
                
                if previousSettings.host == settings.host && previousSettings.ssid == settings.ssid {
                    // If the host and ssid both match the previous host and ssid, tell the downstream publisher not to proceed and keep the
                    // previous settings.
                    return (false, previousSettings)
                }
                
                return (true, settings)
            })
            .compactMap { shouldSaveNewManager, settings -> Settings? in
                guard shouldSaveNewManager else {
                    // Honor an indication from upstream to not create a manager from these settings.
                    return nil
                }
                
                return settings
            }
    }()
    
    // MARK: - Actions
    
    func refresh() throws {
        guard let settings = Self.fetch() else {
            return
        }
        
        settingsSubject.send(settings)
    }
    
    func set(settings: Settings) throws {
        guard settings.uuid == self.settings.uuid else {
            throw Error.uuidMismatch
        }
        
        try Self.set(settings: settings)
        settingsSubject.send(settings)
    }
    
    private static func set(settings: Settings) throws {
        let encoder = JSONEncoder()
        let encodedSettings = try encoder.encode(settings)
        userDefaults.set(encodedSettings, forKey: Self.settingsKey)
    }
    
    private static func fetch() -> Settings? {
        guard let encodedSettings = userDefaults.data(forKey: settingsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let settings = try decoder.decode(Settings.self, from: encodedSettings)
            return settings
        } catch {
            logger.log("Error decoding settings - \(error)")
            return nil
        }
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        do {
            try refresh()
        } catch {
            SettingsManager.logger.log("Error refreshing settings - \(error)")
        }
    }
}
