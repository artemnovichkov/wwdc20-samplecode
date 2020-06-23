/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that draws the character's health level using a bar shape.
*/
import SwiftUI

struct HealthLevelShape: View {
    var level: Double

    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let boxWidth = frame.width / 4
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: frame.minY))
                path.addLines(
                    [CGPoint(x: 0, y: frame.minY),
                     CGPoint(x: boxWidth, y: frame.minY),
                     CGPoint(x: boxWidth, y: frame.maxY),
                     CGPoint(x: 0, y: frame.maxY)])
            }.fill(level > 0 ? Color.green : Color.gray)
            Path { path in
                path.move(to: CGPoint(x: boxWidth + 2, y: frame.minY))
                path.addLines(
                    [CGPoint(x: boxWidth + 2, y: frame.minY),
                     CGPoint(x: boxWidth * 2 + 2, y: frame.minY),
                     CGPoint(x: boxWidth * 2 + 2, y: frame.maxY),
                     CGPoint(x: boxWidth + 2, y: frame.maxY)])
            }.fill(level > 0.24 ? Color.green : Color.gray)
            Path { path in
                path.move(to: CGPoint(x: boxWidth * 2 + 4, y: frame.minY))
                path.addLines(
                    [CGPoint(x: boxWidth * 2 + 4, y: frame.minY),
                     CGPoint(x: boxWidth * 3 + 4, y: frame.minY),
                     CGPoint(x: boxWidth * 3 + 4, y: frame.maxY),
                     CGPoint(x: boxWidth * 2 + 4, y: frame.maxY)])
            }.fill(level > 0.49 ? Color.green : Color.gray)
            Path { path in
                path.move(to: CGPoint(x: boxWidth * 3 + 6, y: frame.minY))
                path.addLines(
                    [CGPoint(x: boxWidth * 3 + 6, y: frame.minY),
                     CGPoint(x: boxWidth * 4 + 6, y: frame.minY),
                     CGPoint(x: boxWidth * 4 + 6, y: frame.maxY),
                     CGPoint(x: boxWidth * 3 + 6, y: frame.maxY)])
            }.fill(level > 0.74 ? Color.green : Color.gray)
        }
    }
}

struct HealthLevelShape_Previews: PreviewProvider {
    static var previews: some View {
        HealthLevelShape(level: 0.5)
            .previewLayout(.fixed(width: 160, height: 20))
    }
}
