/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Text-related accessibility examples
*/

import Foundation
import SwiftUI

struct TextExample: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Automatic Text")

            LargeSpacer()

            Text("Relabeled Text")
                .accessibility(label: Text("Accessibility Label"))

            LargeSpacer()

            Text("Formatted Text")
                .foregroundColor(.red)
                .bold()

            LargeSpacer()

            VStack(alignment: .leading) {
                Text("Stacked Multiple Line Text Line 1")
                Text("This is on another line")
            }
            .accessibilityElement(children: .combine)

            Text("Simple Multiple Line Text\nThis is on another line")
                .lineLimit(nil)
            
            LargeSpacer()

            Text("Text with value and label")
                .accessibility(value: Text("Text Value"))
                .accessibility(label: Text("Text Label"))
        }
    }
}
