/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the Run button.
*/

import SwiftUI
import UIKit

// Custom button style of the run button.
struct RunStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        Circle()
            .fill(Color(UIColor.darkGray))
            .overlay(
                configuration.label
                    .foregroundColor(.white)
                    .font(Font.system(size: 36, weight: .black, design: .default))
            )
            .frame(width: 130, height: 130)
    }
}

struct RunButton: View {
    var action = { print("Run button tapped!") }
    
    var body: some View {
        Button(action: { self.action() }) {
            Text("RUN")
        }
        .buttonStyle(RunStyle())
    }
}

struct RunButton_Previews: PreviewProvider {
    static var previews: some View {
        RunButton()
    }
}
