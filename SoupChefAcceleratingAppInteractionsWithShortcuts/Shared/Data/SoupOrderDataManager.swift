/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data manager that manages an array of `Order` structs.
*/

import Foundation
import Intents
import os.log

/// A concrete `DataManager` for reading and writing data of type `[Order]`.
public class SoupOrderDataManager: DataManager<[Order]> {

    public convenience init() {
        let storageInfo = UserDefaultsStorageDescriptor(key: UserDefaults.StorageKeys.orderHistory.rawValue,
                                                        keyPath: \UserDefaults.orderHistory)
        self.init(storageDescriptor: storageInfo)
    }
    
    override func deployInitialData() {
        dataAccessQueue.sync {
            // Order history is empty the first time the app is used.
            managedData = []
        }
    }

    /// Converts an `Order` into `OrderSoupIntent` and donates it as an interaction to the system
    /// so that this order can be suggested in the future or turned into a voice shortcut for
    /// quickly placing the same order in the future.
    /// - Tag: donate_order
    private func donateInteraction(for order: Order) {
        let interaction = INInteraction(intent: order.intent, response: nil)
        
        // The order identifier is used to match with the donation so the interaction
        // can be deleted if a soup is removed from the menu.
        interaction.identifier = order.identifier.uuidString
        
        interaction.donate { (error) in
            if error != nil {
                if let error = error as NSError? {
                    os_log("Interaction donation failed: %@", log: OSLog.default, type: .error, error)
                }
            } else {
                os_log("Successfully donated interaction")
            }
        }
    }
}

/// Public API for clients of `SoupOrderDataManager`
extension SoupOrderDataManager {
    
    /// Convenience method to access the data with a property name that makes sense in the caller's context.
    public var orderHistory: [Order] {
        return dataAccessQueue.sync {
            return managedData
        }
    }
    
    /// Tries to find an order by its identifier
    public func order(matching identifier: UUID) -> Order? {
        return orderHistory.first { $0.identifier == identifier }
    }
    
    /// Stores the order in the data manager.
    /// Note: This project does not share data between iOS and watchOS. Orders placed on the watch will not display in the iOS order history.
    public func placeOrder(order: Order) {
        //  Access to `managedDataBackingInstance` is only valid on `dataAccessQueue`.
        dataAccessQueue.sync {
            managedData.insert(order, at: 0)
        }
        
        //  Access to UserDefaults is gated behind a separate access queue.
        writeData()
        
        // Donate an interaction to the system.
        donateInteraction(for: order)
    }
    
}

/// Enables observation of `UserDefaults` for the `orderHistory` key.
private extension UserDefaults {
    
    @objc var orderHistory: Data? {
        return data(forKey: StorageKeys.orderHistory.rawValue)
    }
}
