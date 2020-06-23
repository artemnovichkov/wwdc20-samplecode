/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Status View.
*/
import UIKit

final class RBStatusView: UIView {
    
    var status: Status? = nil {
        didSet {
            configure()
        }
    }
    
    override var accessibilityLabel: String? {
        get {
            return status?.accessibilityLabel
        }
        set { _ = newValue }
    }
    
    private let contentView = UIView()
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        return view
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        backgroundColor = .clear
        addSubview(contentView)
        addSubview(imageView)
    }
    
    private func configure() {
        let showSymbols = UIAccessibility.shouldDifferentiateWithoutColor
        
        imageView.isHidden = !showSymbols
        contentView.isHidden = showSymbols
        
        if showSymbols {
            imageView.image = status?.image
            imageView.tintColor = status?.color
        } else {
            contentView.backgroundColor = status?.color
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = bounds
        imageView.frame = bounds
        let dimension: CGFloat = min(bounds.size.width, bounds.size.height)
        contentView.layer.cornerRadius = dimension / 2.0
    }
}

extension Status {

    var color: UIColor? {
        switch self {
        case .purchased(let rating):
            return rating != nil ? .systemGreen : .systemYellow
        case .unpurchased:
            return .systemRed
            
        }
    }
    
    private static let greenImage = UIImage(systemName: "checkmark.circle")
    private static let yellowImage = UIImage(systemName: "questionmark.diamond")
    private static let redImage = UIImage(systemName: "xmark.circle")
    
    var image: UIImage? {
        switch self {
        case .purchased(let rating):
            return rating != nil ? Status.greenImage : Status.yellowImage
        case .unpurchased: return
            Status.redImage
        }
    }
}

extension Status {

    var accessibilityLabel: String {
        switch self {
        case .purchased:
            return NSLocalizedString("Purchased", comment: "")
        case .unpurchased:
            return NSLocalizedString("Not purchased", comment: "")
        }
    }
}
