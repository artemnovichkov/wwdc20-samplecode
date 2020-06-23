/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Text label with specialized appearence.
*/

import UIKit

class OverlayLabel: UILabel, AnimatedTransitioning {
    var insets = UIEdgeInsets(top: 4, left: 12, bottom: 0, right: 12)
    
    init(frame: CGRect, font: UIFont, textColor: UIColor, backgroundColor: UIColor) {
        super.init(frame: frame)
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }

    open override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += insets.left + insets.right
        size.height += insets.top + insets.bottom
        return size
    }

    override open func drawText(in rect: CGRect) {
        return super.drawText(in: rect.inset(by: insets))
    }
}

