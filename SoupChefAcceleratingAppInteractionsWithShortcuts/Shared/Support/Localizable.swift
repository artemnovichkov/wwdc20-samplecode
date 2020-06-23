/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A utility for requesting localized strings for the user interface.
*/

import Foundation

/// A type with a localized string that will load the appropriate localized value for a shortcut.
protocol LocalizableShortcutString {
    
    /// - Parameter useDeferredIntentLocalization: Use deferred localization for any user-facing values that the system will
    ///     display as part of a shortcut on behalf of your app in the future. This allows the system to display the value of the string using
    ///     the device's language settings at the time the shortcut is displayed, which might be a different langsuge from when the shortcut
    ///     was created. This supports users who switch between multiple languages.
    /// - Returns: A localized string for the item description.
    func localizedName(useDeferredIntentLocalization: Bool) -> String
}

/// A type with a localized currency string that is appropiate to display in UI.
protocol LocalizableCurrency {
    
    /// - Returns: A string that displays a locale sensitive currency format.
    var localizedCurrencyValue: String { get }
}
