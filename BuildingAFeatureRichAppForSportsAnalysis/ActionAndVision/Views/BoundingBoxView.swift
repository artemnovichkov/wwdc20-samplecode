/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View that displays a bounding box and optional bezier path.
*/

import UIKit

class BoundingBoxView: UIView, AnimatedTransitioning {
    
    var borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    var borderCornerSize = CGFloat(10)
    var borderWidth = CGFloat(3)
    var borderCornerRadius = CGFloat(4)
    var backgroundOpacity = CGFloat(1)
    var visionRect = CGRect.null
    var visionPath: CGPath? {
        didSet {
            updatePathLayer()
        }
    }
    
    private let pathLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }

    private func initialSetup() {
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        pathLayer.strokeColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1).cgColor
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.lineWidth = 2
        layer.addSublayer(pathLayer)
    }
    
    override func draw(_ rect: CGRect) {
        borderColor.setStroke()
        borderColor.withAlphaComponent(backgroundOpacity).setFill()
        let backgroundPath = UIBezierPath(roundedRect: bounds, cornerRadius: borderCornerRadius)
        backgroundPath.fill()
        let borderPath: UIBezierPath
        let borderRect = bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        if borderCornerSize == 0 {
            borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: borderCornerRadius)
        } else {
            var cornerSizeH = borderCornerSize
            if cornerSizeH > borderRect.width / 2 - borderCornerRadius {
                cornerSizeH = max(borderRect.width / 2 - borderCornerRadius, 0)
            }
            var cornerSizeV = borderCornerSize
            if cornerSizeV > borderRect.height / 2 - borderCornerRadius {
                cornerSizeV = max(borderRect.height / 2 - borderCornerRadius, 0)
            }
            let cornerSize = CGSize(width: cornerSizeH, height: cornerSizeV)
            borderPath = UIBezierPath(cornersOfRect: borderRect, cornerSize: cornerSize, cornerRadius: borderCornerRadius)
        }
        borderPath.lineWidth = borderWidth
        borderPath.stroke()
    }
    
    func containedInside(_ otherBox: BoundingBoxView) -> Bool {
        return otherBox.frame.contains(frame)
    }
    
    private func updatePathLayer() {
        guard let visionPath = self.visionPath else {
            pathLayer.path = nil
            return
        }
        let path = UIBezierPath(cgPath: visionPath)
        path.apply(CGAffineTransform.verticalFlip)
        path.apply(CGAffineTransform(scaleX: bounds.width, y: bounds.height))
        pathLayer.path = path.cgPath
    }
}
