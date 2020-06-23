/*
See LICENSE folder for this sample’s licensing information.

Abstract:
macOS App Delegate for accessibility examples
*/

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!

    override func awakeFromNib() {
        super.awakeFromNib()
        let hostingView = NSHostingView(rootView: AccessibilityExamplesView())
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(self)
    }
}

