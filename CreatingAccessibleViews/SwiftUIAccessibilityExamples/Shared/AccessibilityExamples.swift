/*
See LICENSE folder for this sample’s licensing information.

Abstract:
List of accessibility examples
*/

import Foundation
import SwiftUI

// Standard "large space"
struct LargeSpacer: View {
    var body: some View {
        Spacer(minLength: 25)
            .frame(maxHeight: 25)
    }
}

// Representation of an example
struct AccessibilityExample {
    var name: String
    var view: AnyView

    init<V: View>(name: String, view: V) {
        self.name = name
        self.view = AnyView(view)
    }
}

// Default corner radius to be used for rounding
let defaultCornerRadius: CGFloat = 10

// List of examples to be shown
let examples = [
    AccessibilityExample(name: "Standard Controls", view: StandardControlExample()),
    AccessibilityExample(name: "Images", view: ImageExample()),
    AccessibilityExample(name: "Text", view: TextExample()),
    AccessibilityExample(name: "Containers", view: ContainerExample()),
    AccessibilityExample(name: "Actions", view: ActionExample()),
    AccessibilityExample(name: "ViewRepresentable", view: RepresentableExample())
]

// Visual representaiton of an element
struct AccessibilityElementView: View {
    let color: Color
    let text: Text

    var body: some View {
        RoundedRectangle(cornerRadius: defaultCornerRadius)
            .fill(color)
            .frame(width: 128, height: 48)
            .overlay(text, alignment: .center)
            .foregroundColor(Color.white)
            .overlay(RoundedRectangle(cornerRadius: defaultCornerRadius)
            .strokeBorder(Color.white, lineWidth: 2))
            .overlay(RoundedRectangle(cornerRadius: defaultCornerRadius)
            .strokeBorder(Color.gray, lineWidth: 1))
    }
}
