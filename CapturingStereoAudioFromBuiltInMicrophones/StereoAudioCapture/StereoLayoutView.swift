/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view controller.
*/

import UIKit

class StereoLayoutView: UIView {
    
    private let imageView = UIImageView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        // Configure bezel appearance
        backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        layer.borderColor = UIColor.darkGray.cgColor
        layer.cornerRadius = 8.0
        layer.borderWidth = 1.0
        
        addSubview(imageView)
        imageView.pinToSuperviewEdges(padding: 10)
        imageView.contentMode = .scaleAspectFit
    }
    
    var layout: StereoLayout = .none {
        didSet {
            UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve) {
                self.imageView.image = UIImage(named: self.layout.rawValue)
            } completion: { _ in }
        }
    }
}
