/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that offers controls that tilt the view when incrementing or decrementing a value
*/

import SwiftUI

// MARK: - StepperView

struct StepperView: View {
    @Binding var value: Int {
        didSet {
            tilt = value > oldValue ? 1 : -1
            withAnimation(.interactiveSpring(response: 1, dampingFraction: 1)) {
                tilt = 0
            }
        }
    }
    var label: String
    var configuration: Configuration
    
    @State private var tilt = 0.0

    var body: some View {
        HStack {
            CountButton(mode: .decrement, action: decrement)
                .disabled(value <= configuration.minValue)
                .accessibility(label: Text("Decrease Count"))

            Text(label)
                .frame(width: 150)
                .padding(.vertical)
                .accessibility(sortPriority: 2)

            CountButton(mode: .increment, action: increment)
                .disabled(configuration.maxValue <= value)
                .accessibility(label: Text("Increase Count"))
                .accessibility(sortPriority: 1)
        }
        .accessibilityElement(children: .contain)
        .font(Font.title2.bold())
        .foregroundColor(.primary)
        .background(VisualEffectBlur())
        .contentShape(Capsule())
        .clipShape(Capsule())
        .rotation3DEffect(.degrees(3 * tilt), axis: (x: 0, y: 1, z: 0))
    }
    
    func increment() {
        value = min(max(value + configuration.increment, configuration.minValue), configuration.maxValue)
    }
    
    func decrement() {
        value = min(max(value - configuration.increment, configuration.minValue), configuration.maxValue)
    }
}

// MARK: - StepperView.Configuration

extension StepperView {
    struct Configuration {
        var increment: Int
        var minValue: Int
        var maxValue: Int
    }
}

// MARK: - Previews

struct StepperView_Previews: PreviewProvider {
    static var previews: some View {
        StepperView(
            value: .constant(5),
            label: "Stepper",
            configuration: StepperView.Configuration(increment: 1, minValue: 1, maxValue: 10)
        )
        .padding()
    }
}
