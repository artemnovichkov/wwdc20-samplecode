/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A customized UITableViewCell.
*/
import UIKit

protocol RBCellActionProtocol: AnyObject {
    func didIncreaseRating(cell: RBCell)
    func didDecreaseRating(cell: RBCell)
    func didToggleFavorite(cell: RBCell)
    func didLongPressCell(cell: RBCell)
}

final class RBCell: UITableViewCell {

    class var reusedIdentifier: String {
        return String(describing: self)
    }
    
    weak var delegate: RBCellActionProtocol?

    @IBOutlet private var rbImageView: UIImageView!
    @IBOutlet private var rbName: UILabel!
    @IBOutlet private var rbCaption: UILabel!
    @IBOutlet private var rating: UIStackView!
    @IBOutlet private var statusView: RBStatusView!
    @IBOutlet private var tags: UILabel!
    @IBOutlet private var favoriteButton: UIButton!
    @IBOutlet private var increaseRatingButton: UIButton!
    @IBOutlet private var decreaseRatingButton: UIButton!

    private var longPress: UILongPressGestureRecognizer!
    
    private let highlightOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = .brown
        view.alpha = 0.3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        selectionStyle = .none
        insertSubview(highlightOverlay, at: 0)
        highlightOverlay.isHidden = true

        longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell(_:)))
        addGestureRecognizer(longPress)
    }
    
    func configure(for data: RBViewModel) {
        rbImageView.image = data.coffee.image
        rbName.text = data.coffee.brand
        rbCaption.text = data.coffee.caption
        statusView.status = data.status
        tags.text = data.coffee.tags
        configureFavoriteButton(for: data)
        configureRatingView(for: data)
        configureRatingButtons(for: data)
    }

    private func configureFavoriteButton(for data: RBViewModel) {
        if data.isFavorite {
            favoriteButton.setImage(UIImage(systemName: "suit.heart.fill"), for: .normal)
            favoriteButton.accessibilityLabel = NSLocalizedString("Remove from favorites", comment: "")
        } else {
            favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
            favoriteButton.accessibilityLabel = NSLocalizedString("Add to favorites", comment: "")
        }
        favoriteButton.tintColor = .white
    }

    private func configureRatingView(for data: RBViewModel) {
        if let ratingVal = data.status.rating {
            var filledButtons = ratingVal.rawValue
            rating.subviews.forEach { view in
                if let label = view as? UILabel {
                    label.text = "🤍"
                    if filledButtons > 0 {
                        label.text = "🤎"
                        filledButtons -= 1
                    } else {
                        label.text = "🤍"
                    }
                }
            }
            rating.isAccessibilityElement = true
            rating.accessibilityLabel = String(format: NSLocalizedString("Rated %@ out of 5", comment: ""), String(ratingVal.rawValue))
        } else {
            rating.isAccessibilityElement = true
            rating.accessibilityLabel = NSLocalizedString("Not rated", comment: "")
            rating.subviews.forEach { view in
                if let label = view as? UILabel {
                    label.text = "🤍"
                }
            }
        }
    }

    private func configureRatingButtons(for data: RBViewModel) {
        increaseRatingButton.isEnabled = true
        decreaseRatingButton.isEnabled = true
        if let ratingVal = data.status.rating {
            increaseRatingButton.isEnabled = ratingVal.rawValue < 5
        } else {
            decreaseRatingButton.isEnabled = false
        }
        increaseRatingButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        increaseRatingButton.accessibilityLabel = NSLocalizedString("Increase rating", comment: "")
        decreaseRatingButton.setImage(UIImage(systemName: "hand.thumbsdown"), for: .normal)
        decreaseRatingButton.accessibilityLabel = NSLocalizedString("Decrease rating", comment: "")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        highlightOverlay.isHidden = !selected
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        highlightOverlay.frame = bounds
    }

    @objc
    private func didLongPressCell(_ sender: UILongPressGestureRecognizer) {
        delegate?.didLongPressCell(cell: self)
    }

    @IBAction private func increaseRating(_ sender: Any) {
        delegate?.didIncreaseRating(cell: self)
    }

    @IBAction private func decreaseRating(_ sender: Any) {
        delegate?.didDecreaseRating(cell: self)
    }

    @IBAction private func toggleFavorite(_ sender: Any) {
        delegate?.didToggleFavorite(cell: self)
    }

    // MARK: - Accessibility

    override var isAccessibilityElement: Bool {
        get {
            return true
        }
        set { _ = newValue }
    }
    
    override var accessibilityLabel: String? {
        get {
            var axLabels = [String]()
            if let label = rbName.accessibilityLabel {
                axLabels.append(label)
            }
            if let label = rbCaption.accessibilityLabel {
                axLabels.append(label)
            }
            if let label = tags.accessibilityLabel {
                axLabels.append(label.replacingOccurrences(of: "•", with: ","))
            }
            return axLabels.joined(separator: ", ")
        }
        set { _ = newValue }
    }
    
    override var accessibilityValue: String? {
        get {
            var axValue = ""
            if let label = rating.accessibilityLabel {
                axValue += label + ", "
            }
            if let label = favoriteButton.accessibilityLabel {
                if label.hasPrefix("Remove") {
                    axValue += "Favorite"
                }
            }
            return axValue
        }
        set { _ = newValue }
    }
    
    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            var customActions = super.accessibilityCustomActions ?? [UIAccessibilityCustomAction]()

            let copyAction = UIAccessibilityCustomAction(name: NSLocalizedString("Copy", comment: "")) { (customAction) -> Bool in
                return true
            }
            customActions.append(copyAction)

            let decreaseAction = UIAccessibilityCustomAction(
                    name: NSLocalizedString("Decrease Rating", comment: ""),
                    target: self,
                    selector: #selector(decreaseRating(_:)))
            customActions.append(decreaseAction)

            let increaseAction = UIAccessibilityCustomAction(
                    name: NSLocalizedString("Increase Rating", comment: ""),
                    target: self,
                    selector: #selector(increaseRating(_:)))
            customActions.append(increaseAction)

            let favoriteAction = UIAccessibilityCustomAction(
                    name: NSLocalizedString("Toggle Favorite", comment: ""),
                    target: self,
                    selector: #selector(toggleFavorite(_:)))
            customActions.append(favoriteAction)

            return customActions
        }
        set { _ = newValue }
    }
}
