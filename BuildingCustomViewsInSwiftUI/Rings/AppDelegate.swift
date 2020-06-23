/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The AppDelegate.
*/

import SwiftUI
import Cocoa

private var sharedRing = Ring()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let content = NSHostingController(
            rootView: ContentView().environmentObject(sharedRing))

        let window = NSWindow(contentViewController: content)
        window.setFrame(NSRect(x: 100, y: 100, width: 400, height: 300),
            display: true)
        self.window = window

        window.makeKeyAndOrderFront(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // Main menu commands.

    @IBAction func newWedge(sender: NSControl) {
        withAnimation(.spring()) {
            // Holding Option adds 50 wedges as a single model update.
            if NSApp?.currentEvent?.modifierFlags.contains(.option) ?? false {
                for _ in 0 ..< 50 {
                    sharedRing.addWedge(.random)
                }
            } else {
                sharedRing.addWedge(.random)
            }
        }
    }

    @IBAction func clearWedges(sender: NSControl) {
        withAnimation(.easeInOut(duration: 1.0)) {
            sharedRing.reset()
        }
    }
}
