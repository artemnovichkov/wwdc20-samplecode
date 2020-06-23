/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Class containing static methods for graph drawing.
*/

import Accelerate
import UIKit

class GraphUtility {
    
    static func drawGraphInLayer(_ layer: CAShapeLayer,
                                 strokeColor: CGColor,
                                 lineWidth: CGFloat = 1,
                                 values: [Float],
                                 minimum: Float? = nil,
                                 maximum: Float? = nil,
                                 hScale: CGFloat = 1) {
        
        layer.fillColor = nil
        layer.strokeColor = strokeColor
        layer.lineWidth = lineWidth
        
        let n = vDSP_Length(values.count)
        
        // normalize values in array (i.e. scale to 0-1)...
        var min: Float = 0
        if let minimum = minimum {
            min = minimum
        } else {
            vDSP_minv(values, 1, &min, n)
        }
        
        var max: Float = 0
        if let maximum = maximum {
            max = maximum
        } else {
            vDSP_maxv(values, 1, &max, n)
        }
        
        var scale = 1 / (max - min)
        var minusMin = -min
        
        var scaled = [Float](repeating: 0, count: values.count)
        vDSP_vasm(values, 1, &minusMin, 0, &scale, &scaled, 1, n)
        
        let path = CGMutablePath()
        let xScale = layer.frame.width / CGFloat(values.count)
        let points = scaled.enumerated().map {
            return CGPoint(x: xScale * hScale * CGFloat($0.offset),
                           y: layer.frame.height * CGFloat(1.0 - ($0.element.isFinite ? $0.element : 0)))
        }
        
        path.addLines(between: points)
        layer.path = path
    }
}
