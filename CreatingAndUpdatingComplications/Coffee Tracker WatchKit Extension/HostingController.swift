/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that displays SwiftUI views.
*/

import WatchKit
import Foundation
import SwiftUI

// A controller that hosts SwiftUI views.
class HostingController: WKHostingController<ContentView> {
    
    // MARK: - Body Method
    
    override var body: ContentView {
        // Creates and displays the content wrapper.
        return ContentView()
    }
}
