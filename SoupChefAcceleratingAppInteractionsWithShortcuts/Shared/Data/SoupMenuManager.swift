/*
See LICENSE folder for this sample’s licensing information.

Abstract:

*/

import Foundation

public typealias SoupMenu = Set<MenuItem>

public class SoupMenuManager: DataManager<Set<MenuItem>> {
    
    // MARK: - SoupMenuManager
    
    private static let defaultMenu: SoupMenu = [
        MenuItem(itemName: "Chicken Noodle Soup", price: 4.55, iconImageName: "chicken_noodle_soup", isAvailable: false, isDailySpecial: true),
        MenuItem(itemName: "Minestrone Soup", price: 3.75, iconImageName: "minestrone_soup", isAvailable: true, isDailySpecial: false),
        MenuItem(itemName: "Tomato Soup", price: 2.95, iconImageName: "tomato_soup", isAvailable: true, isDailySpecial: false)
    ]
    
    // MARK: - Data Manager
    
    public convenience init() {
        let storageInfo = UserDefaultsStorageDescriptor(key: UserDefaults.Keys.soupMenuStorage.rawValue,
                                                        keyPath: \UserDefaults.menu)
        self.init(storageDescriptor: storageInfo)
    }
    
    override func deployInitialData() -> Set<MenuItem>! {
        return SoupMenuManager.defaultMenu
    }
}

extension SoupMenuManager {
    
    // MARK: - Public API
    
    public var dailySpecialItems: [MenuItem] {
        var specials: [MenuItem] = []
        dataAccessQueue.sync {
            specials = managedDataBackingInstance.filter { $0.isDailySpecial == true }
        }
        return specials
    }
    
    public var allRegularItems: [MenuItem] {
        var specials: [MenuItem] = []
        dataAccessQueue.sync {
            specials = managedDataBackingInstance.filter { $0.isDailySpecial == false }
        }
        return specials
    }
    
    public var availableRegularItems: [MenuItem] {
        return allRegularItems.filter { $0.isAvailable == true }
    }
    
    public func replaceMenuItem(_ currentMenuItem: MenuItem, with newMenuItem: MenuItem) {
        dataAccessQueue.sync {
            managedDataBackingInstance.remove(currentMenuItem)
            managedDataBackingInstance.insert(newMenuItem)
        }
        
        //  Access to UserDefaults is gated behind a seperate access queue
        writeData()
    }
}

private extension UserDefaults {
    
    @objc var menu: Data? {
        return data(forKey: Keys.soupMenuStorage.rawValue)
    }
}
