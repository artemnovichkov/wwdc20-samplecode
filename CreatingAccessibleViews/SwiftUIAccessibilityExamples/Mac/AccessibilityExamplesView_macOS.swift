/*
See LICENSE folder for this sample’s licensing information.

Abstract:
macOS accessibility examples view
*/

import Foundation
import SwiftUI

// Top-level view for all examples
struct AccessibilityExamplesView: View {
    @State var selection: String? = examples.first?.name

    var selectedExample: AccessibilityExample? {
        selection.flatMap { string in
            examples.first { example in
                example.name == string
            }
        }
    }

    var selectedView: AnyView {
        selectedExample?.view ?? AnyView(Spacer())
    }

    var body: some View {
        HSplitView {
            List(selection: $selection) {
                ForEach(examples, id: \.name) { example in
                    Text(verbatim: example.name)
                }
                Spacer()
            }
            .frame(width: 200, height: 500)

            VStack {
                HStack {
                    selectedView
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 600)
    }
}
