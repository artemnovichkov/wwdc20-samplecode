/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Conversion utilities for converting between `Order` and `OrderSoupIntent`.
*/

import Foundation
import Intents

extension Order {
    public var intent: OrderSoupIntent {
        let orderSoupIntent = OrderSoupIntent()
        orderSoupIntent.quantity = quantity as NSNumber
        
        orderSoupIntent.soup = Soup(identifier: menuItem.identifier.rawValue, display: menuItem.localizedName(useDeferredIntentLocalization: true))
        orderSoupIntent.orderType = orderType
        orderSoupIntent.setImage(INImage(named: menuItem.iconImageName), forParameterNamed: \OrderSoupIntent.soup)
        
        orderSoupIntent.toppings = menuItemToppings.map { (topping) -> Topping in
            return Topping(identifier: topping.rawValue, display: topping.localizedName(useDeferredIntentLocalization: true))
        }
        
        orderSoupIntent.suggestedInvocationPhrase = NSString.deferredLocalizedIntentsString(with: "ORDER_SOUP_SUGGESTED_PHRASE") as String
        
        return orderSoupIntent
    }
    
    public init?(from intent: OrderSoupIntent) {
        let menuManager = SoupMenuManager()
        guard let soup = intent.soup, let menuItem = menuManager.findItem(soup),
            let quantity = intent.quantity
            else { return nil }
        
        let rawToppings = intent.toppings?.compactMap { (toppping) -> MenuItemTopping? in
            guard let toppingID = toppping.identifier else { return nil }
            return MenuItemTopping(rawValue: toppingID)
        } ?? [MenuItemTopping]() // If the result of the map is nil (because `intent.toppings` is nil), provide an empty array.
        
        switch intent.orderType {
        case .unknown:
            self.init(quantity: quantity.intValue, menuItem: menuItem, menuItemToppings: Set(rawToppings))
        case .delivery:
            self.init(quantity: quantity.intValue,
                      menuItem: menuItem,
                      menuItemToppings: Set(rawToppings),
                      deliveryLocation: Location(intent.deliveryLocation))
        case .pickup:
            self.init(quantity: quantity.intValue,
                      menuItem: menuItem,
                      menuItemToppings: Set(rawToppings),
                      storeLocation: Location(intent.storeLocation))
        }
    }
}

extension Topping: CaseIterable {
    
    public typealias AllCases = [Topping]
    
    public static var allCases: [Topping] {
        // Map menu item toppings to custom objects and provide them to the user.
        // The user will be able to choose one or more options.
        return Order.MenuItemTopping.allCases.map { (topping) -> Topping in
            return Topping(identifier: topping.rawValue, display: topping.localizedName(useDeferredIntentLocalization: true))
        }
    }
}

extension Soup {
    
    @available(iOSApplicationExtension 14.0, watchOSApplicationExtension 7.0, *)
    convenience init(menuItem: MenuItem) {
        self.init(identifier: menuItem.identifier.rawValue,
                  display: menuItem.localizedName(useDeferredIntentLocalization: true),
                  subtitle: menuItem.localizedItemDescription(useDeferredIntentLocalization: true),
                  image: INImage(named: menuItem.iconImageName))
    }
    
}

extension Soup: CaseIterable {
    
    public typealias AllCases = [Soup]
    
    public static var allCases: [Soup] {
        let activeMenu = SoupMenuManager()
        
        return activeMenu.findItems(exactlyMatching: [.available, .regularItem], [.available, .dailySpecialItem]).map {
            // Map all available menu items to custom Soup objects and provide them to the user.
            if #available(iOSApplicationExtension 14.0, watchOSApplicationExtension 7.0, *) {
                return Soup(menuItem: $0)
            } else {
                return Soup(identifier: $0.identifier.rawValue, display: $0.localizedName(useDeferredIntentLocalization: true))
            }
        }
    }
    
}
