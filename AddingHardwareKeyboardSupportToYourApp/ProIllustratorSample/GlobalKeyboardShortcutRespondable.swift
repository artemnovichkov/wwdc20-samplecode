/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A protocol defining methods for responding to global keyboard shortcuts.
*/

import Foundation

// The MainViewController root view controller defines global keyboard
// shortcuts but the methods in this protocol are implemented in the child view
// controllers.
//
// The system uses canPerformAction(_:withSender:) to determine if responders
// in the responder chain can actually handle these shortcuts.

/// - Tag: GlobalKeyboardShortcutRespondable
@objc
protocol GlobalKeyboardShortcutRespondable: class {
    /// Mapped to Command-N
    @objc
    optional func createNewItem(_: Any?)
    
    /// Mapped to Backspace or Delete
    @objc
    optional func deleteSelectedItem(_: Any?)
}
