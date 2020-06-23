/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Platform representable accessibility examples
*/

import Foundation
import SwiftUI

struct RepresentableExample: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Element with representable view")
            
            // You can use SwiftUI's Accessibility API to customize to accessibility of
            // AppKit or UIKit represented elements
            RepresentableView()
                .frame(width: 128, height: 48)
                .accessibility(label: Text("representable view accessibility label"))
                .accessibility(value: Text("representable view accessibility value"))

            LargeSpacer()

            Text("Element with representable view controller")
            
            RepresentableViewController()
                .frame(width: 128, height: 48)
                .accessibility(label: Text("representable view controller accessibility label"))
                .accessibility(value: Text("representable view controller accessibility value"))
        }
    }
}
