/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A chart that can display labelled values
*/

import SwiftUI

public struct ChartView: View {
    public var title: String
    public var labeledValues: [(label: String, value: Double)]

    public init(title: String, labeledValues: [(label: String, value: Double)]) {
        self.title = title
        self.labeledValues = labeledValues
    }

    private var chart: PieChart {
        PieChart(labeledValues: labeledValues)
    }

    public var body: some View {
        VStack {
            Text(title)
                .font(.title2)
            PieChartView(chart: chart)
                .aspectRatio(1, contentMode: .fit)
            Spacer()
        }
        .padding()
    }
}

struct PieChartView: View {
    var chart: PieChart

    @State private var showPercentage: Bool = false

    var body: some View {
        GeometryReader { container in
            ZStack {
                ForEach(chart.slices) { slice in
                    PieChartSliceView(
                        slice: slice,
                        frame: container.frame(in: .local),
                        showPercentage: $showPercentage
                    )
                }
            }
        }
        .onTapGesture {
            showPercentage.toggle()
        }
        .contentShape(Circle())
    }
}

struct PieChartSliceView: View {
    var slice: PieChartSlice
    var frame: CGRect
    @Binding var showPercentage: Bool

    @State private var show = false

    private var radius: CGFloat

    init(slice: PieChartSlice, frame: CGRect, showPercentage: Binding<Bool>) {
        self.slice = slice
        self.frame = frame
        self.radius = min(frame.width, frame.height) / 2
        self._showPercentage = showPercentage
    }

    var path: Path {
        var path = Path()
        path.addArc(
            center: frame.center,
            radius: show ? radius : 0.0,
            startAngle: slice.startAngle,
            endAngle: slice.endAngle,
            clockwise: false
        )
        path.addLine(to: frame.center)
        path.closeSubpath()
        return path
    }

    private var occupiedAngle: Angle {
        slice.endAngle - slice.startAngle
    }

    private var midAngle: Angle {
        slice.startAngle + (occupiedAngle) / 2
    }

    private var labelPosition: CGPoint {
        // The larger the slice, the closer to the center, within a range
        // of 0.2x - 0.8x the radius.
        let distanceFromCenter = (radius * 0.2) + (radius * 0.6) * (1 - (CGFloat(occupiedAngle.degrees) / 360))

        let xCoord = distanceFromCenter * CGFloat(cos(midAngle.radians))
        let yCoord = distanceFromCenter * CGFloat(sin(midAngle.radians))

        return CGPoint(x: frame.midX + xCoord, y: frame.midY + yCoord)
    }

    private var label: some View {
        VStack(alignment: .center) {
            Text(slice.label)
                .fontWeight(.semibold)

            if showPercentage {
                Text("\(Int(slice.value.rounded()))%")
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(.white)
    }

    var body: some View {
        path
            .fill(RadialGradient(
                    gradient: Gradient(
                        colors: [
                            slice.gradientStartColor,
                            slice.gradientEndColor
                        ]
                    ),
                    center: .center,
                    startRadius: 0,
                    endRadius: radius * 1.5)
            )
            .overlay(path.stroke(Color.white, lineWidth: 2))
            .scaleEffect(self.show ? 1 : 0.01)
            .overlay(
                label
                    .position(show ? labelPosition : frame.center)
                    .opacity(show ? 1.0 : 0.0)
            )
            .animation(Animation.spring().delay(Double(slice.index) * 0.1))
            .onAppear() {
                self.show = true
            }
    }
}

// MARK: - View Model

struct PieChartSlice {
    var label: String
    var value: Double
    var startAngle: Angle
    var endAngle: Angle
    var gradientStartColor: Color
    var gradientEndColor: Color
    var index: Int
}

struct PieChart {
    var labeledValues: [(label: String, value: Double)]
    var slices: [PieChartSlice]

    init(labeledValues: [(label: String, value: Double)]) {
        self.labeledValues = labeledValues

        let totalValue = labeledValues.reduce(0) { result, labeledValue in
            result + labeledValue.value
        }

        var angle: Angle = .zero
        var slices: [PieChartSlice] = []
        for index in 0..<labeledValues.count {
            let labeledValue = labeledValues[index]
            let ratio = labeledValue.value / totalValue
            let endAngle = angle + .degrees(360 * ratio)

            let hue = Double(index) / Double(labeledValues.count)
            let startColor = Color(hue: hue, saturation: 0.74, brightness: 0.9)
            let endColor = Color(hue: hue, saturation: 0.74, brightness: 0.6)

            let slice = PieChartSlice(
                label: labeledValue.label,
                value: labeledValue.value,
                startAngle: angle,
                endAngle: endAngle,
                gradientStartColor: startColor,
                gradientEndColor: endColor,
                index: index
            )
            slices.append(slice)
            angle = endAngle
        }
        self.slices = slices
    }
}

extension PieChartSlice: Identifiable {
    var id: String {
        label
    }
}

// MARK: - Utilities

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

// MARK: - Previews

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(
            title: "Calorie Chart",
            labeledValues: [
                ("Carbs", 36),
                ("Protein", 53),
                ("Fat", 11)
            ]
        )
    }
}
