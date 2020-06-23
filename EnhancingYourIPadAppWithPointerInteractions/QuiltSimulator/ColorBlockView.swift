/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The UIView subclass containing the individual color blocks in the quilt patchwork.
*/

import UIKit

class ColorBlockView: UIView {
    let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill

        let colors = [UIColor(named: "GreenStrip"),
                      UIColor(named: "YellowStrip"),
                      UIColor(named: "OrangeStrip"),
                      UIColor(named: "RedStrip"),
                      UIColor(named: "PurpleStrip"),
                      UIColor(named: "BlueStrip")]
        for color in colors {
            let colorView = UIView()
            colorView.backgroundColor = color
            stackView.addArrangedSubview(colorView)
        }

        self.addSubview(stackView)
        stackView.leadingAnchor .constraint(equalTo: self.leadingAnchor).isActive = true
        stackView.trailingAnchor .constraint(equalTo: self.trailingAnchor).isActive = true
        stackView.topAnchor .constraint(equalTo: self.topAnchor).isActive = true
        stackView.bottomAnchor .constraint(equalTo: self.bottomAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var rotated: Bool {
        get {
            return (stackView.axis == .horizontal)
        }
        set(newValue) {
            if newValue {
                stackView.axis = .horizontal
            } else {
                stackView.axis = .vertical
            }
        }
    }

    override open var intrinsicContentSize: CGSize {
        return CGSize(width: 200, height: 200)
    }

}
