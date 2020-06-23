/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A DataManager subclass that persists the active menu items.
*/

import Foundation
import os.log

public typealias SoupMenu = Set<MenuItem>

public class SoupMenuManager: DataManager<Set<MenuItem>> {
    
    private static let defaultMenu: SoupMenu = [
        MenuItem(identifier: .chickenNoodleSoup,
                 price: 4.55,
                 itemsInStock: 5,
                 attributes: [.available, .dailySpecialItem]),
        MenuItem(identifier: .newEnglandClamChowder,
                 price: 3.75,
                 itemsInStock: 7,
                 attributes: [.available, .regularItem]),
        MenuItem(identifier: .manhattanClamChowder,
                 price: 3.50,
                 itemsInStock: 2,
                 attributes: [.available, .secretItem]),
        MenuItem(identifier: .tomatoSoup,
                 price: 2.95,
                 itemsInStock: 4,
                 attributes: [.available, .regularItem])
    ]
    
    public var orderManager: SoupOrderDataManager?
    
    public convenience init() {
        let storageInfo = UserDefaultsStorageDescriptor(key: UserDefaults.StorageKeys.soupMenu.rawValue,
                                                        keyPath: \UserDefaults.menu)
        self.init(storageDescriptor: storageInfo)
    }
    
    override func deployInitialData() {
        dataAccessQueue.sync {
            managedData = SoupMenuManager.defaultMenu
        }
        
        updateShortcuts()
    }
}

/// Public API for clients of `SoupMenuManager`
extension SoupMenuManager {
    
    public func replaceMenuItem(_ previousMenuItem: MenuItem, with menuItem: MenuItem) {
        dataAccessQueue.sync {
            managedData.remove(previousMenuItem)
            managedData.insert(menuItem)
        }
        
        //  Access to UserDefaults is gated behind a seperate access queue.
        writeData()
        
        removeDonation(for: menuItem)
        updateShortcuts()
    }
    
    public func findItem(_ soup: Soup) -> MenuItem? {
        return dataAccessQueue.sync {
            return managedData.first { $0.identifier == MenuItem.Identifier(rawValue: soup.identifier!) }
        }
    }
    
    /// Locates items by exactly matching the attributes. This means searching for `[.available]` and `[.available, .regularMenuItem]`
    /// return different results.
    public func findItems(exactlyMatching searchAttributes: MenuItem.Attributes..., searchTerm: String? = nil) -> [MenuItem] {
        return dataAccessQueue.sync {
            return managedData.filter { searchAttributes.contains($0.attributes) }.sortedByName().filter {
                searchTerm == nil || $0.localizedName(useDeferredIntentLocalization: true).localizedCaseInsensitiveContains(searchTerm ?? "")
            }
        }
    }
    
    /// Locates items containing  the attributes. This means searching for `[.regularMenuItem]` will return results for both
    /// `[.regularMenuItem]` and `[.available, .regularMenuItem]`.
    public func findItems(containing searchAttributes: MenuItem.Attributes...) -> [MenuItem] {
        return dataAccessQueue.sync {
     
            return searchAttributes.reduce([MenuItem]()) { (result, attribute) -> [MenuItem] in
                return result + managedData.filter { $0.attributes.contains(attribute) }
            }.sortedByName()
        }
    }
}

/// Enables observation of `UserDefaults` for the `soupMenuStorage` key.
private extension UserDefaults {
    
    @objc var menu: Data? {
        return data(forKey: StorageKeys.soupMenu.rawValue)
    }
}

private extension Array where Element == MenuItem {
    func sortedByName() -> [MenuItem] {
        return sorted { (item1, item2) -> Bool in
            item1.localizedName().localizedCaseInsensitiveCompare(item2.localizedName()) == .orderedAscending
        }
    }
}
