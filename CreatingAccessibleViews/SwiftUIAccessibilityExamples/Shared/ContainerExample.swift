/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Container-related accessibility examples
*/

import Foundation
import SwiftUI

struct ContainerExample: View {
    @State var onState = true

    var body: some View {
        VStack(alignment: .leading) {
            // Create a stack with multiple toggles and a label inside.
            VStack(alignment: .leading) {
                Text("Grouping Container")
                Toggle(isOn: $onState) { Text("Toggle 1") }
                Toggle(isOn: $onState) { Text("Toggle 2") }
                Toggle(isOn: $onState) { Text("Toggle 3") }
                Toggle(isOn: $onState) { Text("Toggle 4") }
            }
            .padding()
            .background(Color.white)
            .border(Color.blue, width: 0.5)
            // Explicitly make a new accessibility element
            // which will contain the children.
            .accessibilityElement(children: .contain)
            .accessibility(label: Text("Grouping Container"))

            LargeSpacer()

            VStack(alignment: .leading) {
                Text("Hiding Container")
                Image("dot_red", label: Text("Red Dot"))
                    .resizable()
                    .frame(width: 48, height: 48)
                    .scaledToFit()
                Image("dot_green", label: Text("Green Dot"))
                    .resizable()
                    .frame(width: 48, height: 48)
                    .scaledToFit()
            }
            .padding()
            .background(Color.white)
            .border(Color.blue, width: 0.5)
            // Hide all the accessibility elements that come from controls
            // inside this stack
            .accessibility(hidden: true)
            // Create a new accessibility element to contain them
            .accessibilityElement(children: .contain)
            .accessibility(label: Text("Hiding Container"))

            LargeSpacer()

            // Two text elements in a vertical stack, with different hints.
            VStack(alignment: .leading) {
                Text("Combining").accessibility(hint: Text("First Hint"))
                Text("Container").accessibility(hint: Text("Second Hint"))
            }
            .padding()
            .background(Color.white)
            .border(Color.blue, width: 0.5)
            // Explicitly create a container that will combine it's children
            // This will have a combined label and hint from the text elements
            // below it. And the text elements will be hidden.
            .accessibilityElement(children: .combine)
        }
    }
}
