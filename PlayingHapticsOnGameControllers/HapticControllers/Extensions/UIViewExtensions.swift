/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Swift extensions on UIView.
*/

import UIKit

// Extend Interface Builder to expose view border parameters.
@IBDesignable extension UIView {
    
    @IBInspectable var borderColor: UIColor? {
        set { layer.borderColor = newValue?.cgColor }
        get {
            guard let color = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        set { layer.borderWidth = newValue }
        get { layer.borderWidth }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
            clipsToBounds = newValue > 0
        }
        get { layer.cornerRadius}
    }
}
