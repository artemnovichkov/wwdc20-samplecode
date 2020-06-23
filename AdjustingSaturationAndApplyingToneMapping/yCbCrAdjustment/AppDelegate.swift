/*
See LICENSE folder for this sample’s licensing information.

Abstract:
App delegate.
*/

import Cocoa
import SwiftUI

let hideFurniture = false

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
       
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1024, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.title = "YCbCr Image Adjustment"
        
        guard let ycbcrAdjustment = YCbCrAdjustment(image: #imageLiteral(resourceName: "Rainbow_1.png")) else {
            fatalError("Unable to create `YCbCrAdjustment` from image.")
        }

        if hideFurniture {
            window.setContentSize(NSSize(width: ycbcrAdjustment.sourceCGImage.width / 2,
                                         height: ycbcrAdjustment.sourceCGImage.height / 2))
            window.showsResizeIndicator = false
            window.contentResizeIncrements = NSSize(width: Double.greatestFiniteMagnitude,
                                                    height: Double.greatestFiniteMagnitude)
            window.center()
            
            window.styleMask = .borderless
        }
        
        window.contentView = NSHostingView(rootView: ContentView()
            .environmentObject(ycbcrAdjustment))

        window.makeKeyAndOrderFront(nil)
    }
}

