/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Image-related accessibility examples
*/

import Foundation
import SwiftUI

// Visual frame for an image
struct ExampleImageView: View {
    let image: Image

    init(_ image: Image) {
        self.image = image
    }

    var body: some View {
        image.resizable()
            .frame(width: 64, height: 64)
            .scaledToFit()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray)
                    )
            )
    }
}

struct ImageExample: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Unlabeled Image")

            // This image creates an accessibility element, but has no label.
            ExampleImageView(Image("dot_green"))

            LargeSpacer()

            Text("Labeled Images")

            HStack {
                // This image uses an explicit accessibility label via the API.
                ExampleImageView(Image("dot_red"))
                    .accessibility(label: Text("Red Dot Image"))

                // This image is created with an explicit accessibility label.
                ExampleImageView(Image("dot_green", label: Text("Green Dot")))

                // This image gets an implicit accessibility label, because
                // the string string "dot_yellow" is in a localizable strings
                // file.
                ExampleImageView(Image("dot_yellow"))
            }

            LargeSpacer()

            Text("Decorative Image")
            
            // This image is explicitly marked decorative, so it does not
            // create an accessibility element.
            ExampleImageView(Image(decorative: "dot_green"))
        }
    }
}
