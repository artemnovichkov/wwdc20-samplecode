/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This type encapsulates the attributes of a soup order.
*/

import Foundation
import Contacts
import CoreLocation
import Intents

public struct Order: Codable {
    
    public enum MenuItemTopping: String, Codable, CaseIterable, LocalizableShortcutString {
        case cheese = "Cheese"
        case redPepper = "Red Pepper"
        case croutons = "Croutons"

        // See comments on `LocalizableShortcutString` to understand the `useDeferredIntentLocalization` value.
        public func localizedName(useDeferredIntentLocalization: Bool = false) -> String {
            if useDeferredIntentLocalization {
                return NSString.deferredLocalizedIntentsString(with: localizationKey) as String
            } else {
              return NSLocalizedString(localizationKey, comment: "Topping name")
            }
        }
        
        private var localizationKey: String {
            switch self {
            case .cheese:
                return "CHEESE"
            case .redPepper:
                return "RED_PEPPER"
            case .croutons:
                return "CROUTONS"
            }
        }
    }
    
    public static let storeLocations: [CLPlacemark] = [
        CLPlacemark(location: CLLocation(latitude: 37.795_316, longitude: -122.393_76),
                    name: "Ferry Building",
                    postalAddress: nil),
        CLPlacemark(location: CLLocation(latitude: 37.779_379, longitude: -122.418_433),
                    name: "Civic Center",
                    postalAddress: nil)
    ]

    public let date: Date
    public let identifier: UUID
    public let menuItem: MenuItem
    public var quantity: Int
    public var menuItemToppings: Set<MenuItemTopping>
    public var total: Decimal {
        return Decimal(quantity) * menuItem.price
    }
    public var storeLocation: Location?
    public var deliveryLocation: Location?
    public var orderType: OrderType
    
    public init(date: Date = Date(),
                identifier: UUID = UUID(),
                quantity: Int,
                menuItem: MenuItem,
                menuItemToppings: Set<MenuItemTopping>,
                storeLocation: Location? = nil) {
        self.date = date
        self.identifier = identifier
        self.quantity = quantity
        self.menuItem = menuItem
        self.menuItemToppings = menuItemToppings
        self.orderType = .pickup
        self.storeLocation = storeLocation
    }
    
    public init(date: Date = Date(),
                identifier: UUID = UUID(),
                quantity: Int,
                menuItem: MenuItem,
                menuItemToppings: Set<MenuItemTopping>, deliveryLocation: Location?) {
        self.init(date: date, identifier: identifier, quantity: quantity, menuItem: menuItem, menuItemToppings: menuItemToppings)
        self.deliveryLocation = deliveryLocation
        self.orderType = .delivery
    }
}

extension Order: Hashable {
    
    ///  SoupChef considers orders with the same contents (menuItem, quantity, menuItemToppings) to be identical.
    /// The data and idenfier properties are unique to an instance of an order (regardless of contents) and are not
    /// considered when determining equality.
    public static func ==(lhs: Order, rhs: Order) -> Bool {
        return lhs.menuItem == rhs.menuItem &&
            rhs.quantity == lhs.quantity &&
            rhs.menuItemToppings == lhs.menuItemToppings
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(menuItem)
        hasher.combine(quantity)
        hasher.combine(menuItemToppings)
    }
}

extension Order: LocalizableCurrency {

    public var localizedCurrencyValue: String {
        return NumberFormatter.currencyFormatter.string(from: total as NSDecimalNumber) ?? ""
    }
}

public struct Location: Codable {
    public var name: String?
    public var latitude: Double
    public var longitude: Double
    
    init(name: String?, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init?(_ placemark: CLPlacemark?) {
        guard let placemark = placemark, let location = placemark.location else { return nil }
        self.init(name: placemark.name, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
}

extension Location {
    public var location: CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
    
    public var placemark: CLPlacemark {
        return CLPlacemark(location: self.location, name: self.name, postalAddress: nil)
    }
}

extension OrderType: Codable {
    
}
