/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Wedge view.
*/

import SwiftUI

/// A view drawing a single colored ring wedge.
struct WedgeView: View {
    var wedge: Ring.Wedge

    var body: some View {
        // Fill the wedge shape with its chosen gradient.

        WedgeShape(wedge).fill(wedge.foregroundGradient)
    }
}

struct WedgeShape: Shape {
    var wedge: Ring.Wedge
    init(_ wedge: Ring.Wedge) { self.wedge = wedge }

    func path(in rect: CGRect) -> Path {
        let points = WedgeGeometry(wedge, in: rect)

        var path = Path()
        path.addArc(center: points.center, radius: points.innerRadius,
            startAngle: .radians(wedge.start), endAngle: .radians(wedge.end),
            clockwise: false)
        path.addLine(to: points[.bottomTrailing])
        path.addArc(center: points.center, radius: points.outerRadius,
            startAngle: .radians(wedge.end), endAngle: .radians(wedge.start),
            clockwise: true)
        path.closeSubpath()
        return path
    }

    var animatableData: Ring.Wedge.AnimatableData {
        get { wedge.animatableData }
        set { wedge.animatableData = newValue }
    }
}

/// Helper type for creating view-space points within a wedge.
private struct WedgeGeometry {
    var wedge: Ring.Wedge
    var center: CGPoint
    var innerRadius: CGFloat
    var outerRadius: CGFloat

    init(_ wedge: Ring.Wedge, in rect: CGRect) {
        self.wedge = wedge
        center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        innerRadius = radius / 4
        outerRadius = innerRadius +
            (radius - innerRadius) * CGFloat(wedge.depth)
    }

    /// Returns the view location of the point in the wedge at unit-
    /// space location `unitPoint`, where the X axis of `p` moves around the
    /// wedge arc and the Y axis moves out from the inner to outer
    /// radius.
    subscript(unitPoint: UnitPoint) -> CGPoint {
        let radius = lerp(innerRadius, outerRadius, by: unitPoint.y)
        let angle = lerp(wedge.start, wedge.end, by: Double(unitPoint.x))

        return CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                       y: center.y + CGFloat(sin(angle)) * radius)
    }
}

/// Colors derived from the wedge hue for drawing.
extension Ring.Wedge {
    var startColor: Color {
        return Color(hue: hue, saturation: 0.4, brightness: 0.8)
    }

    var endColor: Color {
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }

    var backgroundColor: Color {
        Color(hue: hue, saturation: 0.5, brightness: 0.8, opacity: 0.1)
    }

    var foregroundGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            center: .center,
            startAngle: .radians(start),
            endAngle: .radians(end)
        )
    }
}

/// Linearly interpolate from `from` to `to` by the fraction `amount`.
private func lerp<T: BinaryFloatingPoint>(_ fromValue: T, _ toValue: T, by amount: T) -> T {
    return fromValue + (toValue - fromValue) * amount
}
