/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view to display selection state, and to resize a shape.
*/

import UIKit

class ShapeSelectionView: UIView {
    private class SelectionGrabberView: UIView {
        init() {
            super.init(frame: .zero)
            backgroundColor = .clear
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            let context = UIGraphicsGetCurrentContext()
            UIColor.white.setFill()
            context?.fillEllipse(in: rect)
        }
    }
    
    private let topLeftGrabber = SelectionGrabberView()
    private let topRightGrabber = SelectionGrabberView()
    private let bottomLeftGrabber = SelectionGrabberView()
    private let bottomRightGrabber = SelectionGrabberView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        
        addSubview(topLeftGrabber)
        addSubview(topRightGrabber)
        addSubview(bottomLeftGrabber)
        addSubview(bottomRightGrabber)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.gray.setStroke()
        
        let context = UIGraphicsGetCurrentContext()
        context?.stroke(rect, width: 3.0)
    }
    
    override func layoutSubviews() {
        let knobSize = CGSize(width: 10.0, height: 10.0)
        
        let centerOffset = (knobSize.width / 2)
        topLeftGrabber.frame = CGRect(origin: CGPoint(x: -centerOffset, y: -centerOffset), size: knobSize)
        topRightGrabber.frame = CGRect(origin: CGPoint(x: bounds.width - centerOffset, y: -centerOffset), size: knobSize)
        bottomLeftGrabber.frame = CGRect(origin: CGPoint(x: -centerOffset, y: bounds.height - centerOffset), size: knobSize)
        bottomRightGrabber.frame = CGRect(origin: CGPoint(x: bounds.width - centerOffset, y: bounds.height - centerOffset), size: knobSize)
    }
}
