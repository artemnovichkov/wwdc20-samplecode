/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This type encapsulates the attributes of a soup menu item.
*/

import Foundation

public struct MenuItem: Codable, Hashable {
    
    public enum Identifier: String, Codable {
        case chickenNoodleSoup
        case tomatoSoup
        case newEnglandClamChowder
        case manhattanClamChowder
    }
    
    public struct Attributes: OptionSet, Codable, Hashable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let available = Attributes(rawValue: 1 << 0)
        
        public static let regularItem = Attributes(rawValue: 1 << 1)
        public static let dailySpecialItem = Attributes(rawValue: 1 << 2)
        public static let secretItem = Attributes(rawValue: 1 << 3)
    }
    
    public let identifier: Identifier
    
    public let price: Decimal
    public var itemsInStock: Int
    public var attributes: Attributes
}

extension MenuItem {
    
    public var iconImageName: String {
        switch identifier {
        case .newEnglandClamChowder, .manhattanClamChowder:
            return "clam_chowder"
        case .chickenNoodleSoup:
            return "chicken_noodle_soup"
        case .tomatoSoup:
            return "tomato_soup"
        }
    }
}

extension MenuItem: LocalizableShortcutString {
    
    // See comments on `LocalizableShortcutString` to understand the `useDeferredIntentLocalization` value.
    public func localizedName(useDeferredIntentLocalization: Bool = false) -> String {
        return localizedString(for: localizedNameKey, useDeferredIntentLocalization: useDeferredIntentLocalization)
    }
    
    // See comments on `LocalizableShortcutString` to understand the `useDeferredIntentLocalization` value.
    public func localizedItemDescription(useDeferredIntentLocalization: Bool = false) -> String {
        return localizedString(for: localizedDescriptionKey, useDeferredIntentLocalization: useDeferredIntentLocalization)
    }
    
    // See comments on `LocalizableShortcutString` to understand the `useDeferredIntentLocalization` value.
    public func localizedItemSubtitle(useDeferredIntentLocalization: Bool = false) -> String {
        return localizedString(for: localizedSubtitleKey, useDeferredIntentLocalization: useDeferredIntentLocalization)
    }
    
    // See comments on `LocalizableShortcutString` to understand the `useDeferredIntentLocalization` value.
    private func localizedString(for key: String, useDeferredIntentLocalization: Bool = false) -> String {
        if useDeferredIntentLocalization {
            return NSString.deferredLocalizedIntentsString(with: key) as String
        } else {
          return NSLocalizedString(key, comment: "Menu item")
        }
    }
    
    private var localizedNameKey: String {
        switch identifier {
        case .newEnglandClamChowder:
            return "NE_CLAM_CHOWDER"
        case .manhattanClamChowder:
            return "MANHATTAN_CLAM_CHOWDER"
        case .chickenNoodleSoup:
            return "CHICKEN_NOODLE_SOUP"
        case .tomatoSoup:
            return "TOMATO_SOUP"
        }
    }
    
    private var localizedSubtitleKey: String {
        return localizedNameKey + "_SUBTITLE"
    }
    
    private var localizedDescriptionKey: String {
        switch identifier {
        case .newEnglandClamChowder:
            return "NE_CLAM_CHOWDER_DESCRIPTION"
        case .manhattanClamChowder:
            return "MANHATTAN_CLAM_CHOWDER_DESCRIPTION"
        case .chickenNoodleSoup:
            return "CHICKEN_NOODLE_SOUP_DESCRIPTION"
        case .tomatoSoup:
            return "TOMATO_SOUP_DESCRIPTION"
        }
    }
}

extension MenuItem: LocalizableCurrency {
    
    public var localizedCurrencyValue: String {
        return NumberFormatter.currencyFormatter.string(from: price as NSDecimalNumber) ?? ""
    }
}
