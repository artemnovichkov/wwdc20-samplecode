/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Swift extensions to simplify view handling in the sample app.
*/

import UIKit

public extension UIView {

    func pinToSuperviewEdges(padding: CGFloat = 0.0) {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: padding),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: padding),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -padding),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -padding)
        ])
    }
}
