/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the menu button.
*/

import SwiftUI

struct MenuStyle: ButtonStyle {
    var symbolName: String
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        VStack {
            Image(systemName: self.symbolName)
            .resizable()
            .frame(width: 60, height: 60, alignment: .center)
            Spacer().frame(width: 8, height: 8, alignment: .center)
            configuration.label
            .foregroundColor(.white)
            .font(Font.system(size: 14, weight: .regular, design: .default))
        }
    }
}

struct MenuButton: View {
    var title = "Resume"
    var symbolName = "pause.circle.fill"
    var action = { print("Menu button tapped!") }

    var body: some View {
            Button(action: { self.action() }) {
                    Text(self.title)
            }
            .buttonStyle(MenuStyle(symbolName: symbolName))
        }
}

struct MenuButton_Previews: PreviewProvider {
    static var previews: some View {
        
                MenuButton(title: "End", symbolName: "xmark.circle.fill", action: {})

    }
}
