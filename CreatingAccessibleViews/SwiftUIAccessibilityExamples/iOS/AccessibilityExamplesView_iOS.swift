/*
See LICENSE folder for this sample’s licensing information.

Abstract:
iOS accessibility examples view
*/

import Foundation
import SwiftUI

// Contents view for a specific example
struct ExampleView: View {
    let example: AccessibilityExample

    init(_ example: AccessibilityExample) {
        self.example = example
    }

    var body: some View {
        VStack {
            example.view
                .padding(.horizontal)
            
            Spacer()
        }
    }
}

// Top-level view for all examples
struct AccessibilityExamplesView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(examples, id: \.name) { example in
                    NavigationLink(destination: ExampleView(example)) {
                        Text(verbatim: example.name)
                    }
                }
            }
            .navigationBarTitle(Text("Examples"))
        }
    }
}
