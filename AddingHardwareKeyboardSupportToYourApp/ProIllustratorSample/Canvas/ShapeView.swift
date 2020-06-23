/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays a shape.
*/

import UIKit

class ShapeView: UIView {
    var shape: Shape?
    let selectionView = ShapeSelectionView(frame: .zero)
    
    var isSelected: Bool = false {
        didSet {
            backgroundColor = isSelected ? .systemBlue : .clear
            selectionView.isHidden = !isSelected
        }
    }
    
    init(shape: Shape) {
        self.shape = shape
        super.init(frame: shape.rect)
        
        backgroundColor = .clear
        
        selectionView.isUserInteractionEnabled = false
        selectionView.backgroundColor = .clear
        selectionView.isHidden = true
        addSubview(selectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let shape = self.shape, let context = UIGraphicsGetCurrentContext() {
            shape.color.setFill()
            switch shape.style {
            case .rectangle:
                context.fill(rect)
            case .circle:
                context.fillEllipse(in: rect)
            }
        }
    }
    
    override func layoutSubviews() {
        selectionView.frame = bounds
    }
}
