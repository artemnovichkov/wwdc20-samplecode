/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The UIView subclass containing the collection of color blocks that makes up the "background" of the quilt.
*/

import UIKit

class PatchworkView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        var phase = false
        for _ in 1...4 {
            let verticalStack = UIStackView()
            verticalStack.axis = .vertical
            for _ in 1...3 {
                let colorBlock = ColorBlockView()
                colorBlock.rotated = phase
                phase = !phase
                verticalStack.addArrangedSubview(colorBlock)
            }
            horizontalStack.addArrangedSubview(verticalStack)
        }
        self.addSubview(horizontalStack)
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        horizontalStack.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
