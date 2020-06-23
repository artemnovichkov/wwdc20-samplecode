/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension on SoupMenuManager that creates shortcuts to menu items.
*/

import Foundation
import Intents
import os.log

/// This extension contains supporting methods for using the Intents framework.
extension SoupMenuManager {
    
    /// Inform Siri of changes to the menu.
    func updateShortcuts() {
        updateMenuItemShortcuts()
        updateSuggestions()
    }
    
    /// Each time an order is placed, we instantiate an INInteraction object and donate it to the system (see SoupOrderDataManager extension).
    /// After instantiating the INInteraction, its identifier property is set to the same value as the identifier
    /// property for the corresponding order. Compile a list of all the order identifiers to pass to the INInteraction delete method.
    func removeDonation(for menuItem: MenuItem) {
        if menuItem.attributes.contains(.available) == false {
            guard let orderHistory = orderManager?.orderHistory else { return }
            let ordersAssociatedWithRemovedMenuItem = orderHistory.filter { $0.menuItem.identifier == menuItem.identifier }
            let orderIdentifiersToRemove = ordersAssociatedWithRemovedMenuItem.map { $0.identifier.uuidString }
            
            INInteraction.delete(with: orderIdentifiersToRemove) { (error) in
                if error != nil {
                    if let error = error as NSError? {
                        os_log("Failed to delete interactions with error: %@", log: OSLog.default, type: .error, error)
                    }
                } else {
                    os_log("Successfully deleted interactions")
                }
            }
        }
    }
    
    /// Configures a secret menu item to be made available as a relevant shortcut. This item
    /// is not available on the regular menu to demonstrate how relevant shortcuts are able to
    /// suggest tasks the user may want to start, but haven't used in the app before.
    private func updateSuggestions() {
        
        let availableSecretItems = findItems(exactlyMatching: [.available, .secretItem])
        let secretMenuSuggestedShortcuts = availableSecretItems.compactMap { (menuItem) -> INRelevantShortcut? in
            let order = Order(quantity: 1, menuItem: menuItem, menuItemToppings: [])
            let orderIntent = order.intent
            
            guard let shortcut = INShortcut(intent: orderIntent) else { return nil }
            
            let suggestedShortcut = INRelevantShortcut(shortcut: shortcut)
            
            let localizedTitle = NSString.deferredLocalizedIntentsString(with: "ORDER_LUNCH_TITLE") as String
            let template = INDefaultCardTemplate(title: localizedTitle)
            
            // Using the subtitle instead of item name because relevant shortcuts have
            // different guidelines for wording and capitalization. See the Siri section of
            // the Human Interface Guidelines.
            template.subtitle = menuItem.localizedItemSubtitle(useDeferredIntentLocalization: true)
            template.image = INImage(named: menuItem.iconImageName)
            
            suggestedShortcut.watchTemplate = template
            
            // Make a lunch suggestion when arriving to work.
            let routineRelevanceProvider = INDailyRoutineRelevanceProvider(situation: .work)
            
            // This sample uses a single relevance provider, but using multiple relevance providers is supported.
            suggestedShortcut.relevanceProviders = [routineRelevanceProvider]
            
            return suggestedShortcut
        }
            
        INRelevantShortcutStore.default.setRelevantShortcuts(secretMenuSuggestedShortcuts) { (error) in
            if let error = error as NSError? {
                os_log("Providing relevant shortcut failed. \n%@", log: OSLog.default, type: .error, error)
            } else {
                os_log("Providing relevant shortcut succeeded.")
            }
        }
    }
    
    /// Provides shortcuts for orders the user may want to place, based on a menu item's availability.
    /// The results of this method are visible in the Shortcuts app.
    private func updateMenuItemShortcuts() {
        
        let availableRegularItems = findItems(exactlyMatching: [.available, .regularItem])
        let availableShortcuts = availableRegularItems.compactMap { (menuItem) -> INShortcut? in
            let order = Order(quantity: 1, menuItem: menuItem, menuItemToppings: [])
            return INShortcut(intent: order.intent)
        }
        
        INVoiceShortcutCenter.shared.setShortcutSuggestions(availableShortcuts)
    }
}
