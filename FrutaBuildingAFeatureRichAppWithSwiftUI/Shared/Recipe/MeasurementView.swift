/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that can display an arbritrary DisplayableMeasurement
*/

import SwiftUI
import NutritionFacts

struct MeasurementView: View {
    let measurement: DisplayableMeasurement

    init(measurement: DisplayableMeasurement) {
        self.measurement = measurement
    }

    var backgroundColor: Color {
        #if os(iOS)
        return Color(.tertiarySystemFill)
        #else
        return Color(.windowBackgroundColor)
        #endif
    }

    var body: some View {
        HStack {
            measurement.unitImage
                .foregroundColor(.secondary)

            Text(measurement.localizedSummary())
        }
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView(
            measurement: Measurement(value: 1.5, unit: UnitVolume.cups)
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
