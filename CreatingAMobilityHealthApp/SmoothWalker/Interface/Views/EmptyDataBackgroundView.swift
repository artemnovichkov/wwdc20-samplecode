/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view used for the background of table views when there is no data.
*/

import UIKit

private extension CGFloat {
    static let horizontalInset: CGFloat = 60
}

/// A view with a centered label to communicate there is no data available.
class EmptyDataBackgroundView: UIView {
    
    var labelText: String!
    
    init(message: String) {
        self.labelText = message
        
        super.init(frame: .zero)
        
        setupViews()
        
        label.text = message
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupViews() {
        addSubview(label)
        
        addConstraints()
    }
    
    var label: UILabel = {
        let label = UILabel()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 22, weight: .regular)
        label.numberOfLines = 0
        
        return label
    }()
    
    func addConstraints() {
        var constraints: [NSLayoutConstraint] = []
        
        constraints += addLabelConstraints()
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func addLabelConstraints() -> [NSLayoutConstraint] {
        return [
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .horizontalInset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.horizontalInset),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }
}
