/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button for either incrementing or decrementing a binding.
*/

import SwiftUI

// MARK: - CountButton

struct CountButton: View {
    var mode: Mode
    var action: () -> Void

    @Environment(\.isEnabled) var isEnabled

    @ViewBuilder var image: some View {
        switch mode {
        case .increment:
            Image(systemName: isEnabled ? "plus.circle.fill" : "plus.circle")
        case .decrement:
            Image(systemName: isEnabled ? "minus.circle.fill" : "minus.circle")
        }
    }

    public var body: some View {
        Button(action: action) {
            image
                .imageScale(.large)
                .padding()
                .contentShape(Rectangle())
                .opacity(0.5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - CountButton.Mode

extension CountButton {
    enum Mode {
        case increment
        case decrement
    }
}

// MARK: - Previews

struct CountButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CountButton(mode: .increment, action: {})
            CountButton(mode: .decrement, action: {})
            CountButton(mode: .increment, action: {}).disabled(true)
            CountButton(mode: .decrement, action: {}).disabled(true)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
